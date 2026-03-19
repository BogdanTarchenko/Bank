package com.bank.core.service;

import com.bank.core.dto.MoneyOperationRequest;
import com.bank.core.dto.OperationResponse;
import com.bank.core.dto.TransferRequest;
import com.bank.core.dto.kafka.OperationEvent;
import com.bank.core.dto.mapper.OperationMapper;
import com.bank.core.exception.AccountClosedException;
import com.bank.core.exception.AccountNotFoundException;
import com.bank.core.exception.InsufficientFundsException;
import com.bank.core.model.*;
import com.bank.core.model.Currency;
import com.bank.core.repository.AccountRepository;
import com.bank.core.repository.OperationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class OperationService {

    private final AccountRepository accountRepository;
    private final OperationRepository operationRepository;
    private final KafkaOperationProducer kafkaProducer;
    private final ExchangeRateService exchangeRateService;
    private final OperationNotificationService notificationService;

    // --- Command methods (produce to Kafka) ---

    public void requestDeposit(Long accountId, MoneyOperationRequest request) {
        Account account = findActiveAccount(accountId);
        OperationEvent event = new OperationEvent(
                UUID.randomUUID(),
                accountId,
                OperationType.DEPOSIT,
                request.amount(),
                account.getCurrency(),
                null,
                null,
                "Пополнение счёта"
        );
        kafkaProducer.send(event);
    }

    public void requestWithdrawal(Long accountId, MoneyOperationRequest request) {
        Account account = findActiveAccount(accountId);
        // Предварительная проверка баланса (до отправки в Kafka)
        validateSufficientFunds(account, request.amount());

        OperationEvent event = new OperationEvent(
                UUID.randomUUID(),
                accountId,
                OperationType.WITHDRAWAL,
                request.amount(),
                account.getCurrency(),
                null,
                null,
                "Снятие со счёта"
        );
        kafkaProducer.send(event);
    }

    public void requestTransfer(TransferRequest request) {
        Account from = findActiveAccount(request.fromAccountId());
        Account to = findActiveAccount(request.toAccountId());
        // Предварительная проверка баланса (до отправки в Kafka)
        validateSufficientFunds(from, request.amount());

        BigDecimal exchangeRate = null;
        if (from.getCurrency() != to.getCurrency()) {
            exchangeRate = exchangeRateService.getRate(from.getCurrency(), to.getCurrency());
        }

        OperationEvent event = new OperationEvent(
                UUID.randomUUID(),
                request.fromAccountId(),
                OperationType.TRANSFER_OUT,
                request.amount(),
                from.getCurrency(),
                request.toAccountId(),
                exchangeRate,
                "Перевод на счёт #" + request.toAccountId()
        );
        kafkaProducer.send(event);
    }

    // --- Processing method (called from Kafka consumer) ---

    @Transactional
    public void processOperation(OperationEvent event) {
        // 1. Идемпотентность
        if (operationRepository.existsByIdempotencyKey(event.idempotencyKey())) {
            log.info("Операция {} уже обработана, пропускаем", event.idempotencyKey());
            return;
        }

        switch (event.type()) {
            case DEPOSIT -> processDeposit(event);
            case WITHDRAWAL -> processWithdrawal(event);
            case TRANSFER_OUT -> processTransfer(event);
            default -> log.warn("Неизвестный тип операции: {}", event.type());
        }
    }

    @Transactional(readOnly = true)
    public Page<OperationResponse> getOperationsByAccountId(Long accountId, int page, int size) {
        // Проверяем что счёт существует
        accountRepository.findById(accountId)
                .orElseThrow(() -> new AccountNotFoundException(accountId));

        return operationRepository.findByAccountIdOrderByCreatedAtDesc(accountId, PageRequest.of(page, size))
                .map(OperationMapper::toResponse);
    }

    // --- Private processing methods ---

    private void processDeposit(OperationEvent event) {
        Account account = lockAccount(event.accountId());
        validateAccountActive(account);

        account.setBalance(account.getBalance().add(event.amount()));
        accountRepository.save(account);

        Operation operation = buildOperation(event, account, null);
        operationRepository.save(operation);

        log.info("Пополнение: счёт={}, сумма={} {}", account.getId(), event.amount(), event.currency());
        notificationService.notifyNewOperation(OperationMapper.toResponse(operation));
    }

    private void processWithdrawal(OperationEvent event) {
        Account account = lockAccount(event.accountId());
        validateAccountActive(account);
        validateSufficientFunds(account, event.amount());

        account.setBalance(account.getBalance().subtract(event.amount()));
        accountRepository.save(account);

        Operation operation = buildOperation(event, account, null);
        operationRepository.save(operation);

        log.info("Снятие: счёт={}, сумма={} {}", account.getId(), event.amount(), event.currency());
        notificationService.notifyNewOperation(OperationMapper.toResponse(operation));
    }

    private void processTransfer(OperationEvent event) {
        // Блокируем счета в порядке возрастания ID для предотвращения deadlock
        Long fromId = event.accountId();
        Long toId = event.relatedAccountId();

        Account fromAccount;
        Account toAccount;

        if (fromId < toId) {
            fromAccount = lockAccount(fromId);
            toAccount = lockAccount(toId);
        } else {
            toAccount = lockAccount(toId);
            fromAccount = lockAccount(fromId);
        }

        validateAccountActive(fromAccount);
        validateAccountActive(toAccount);
        validateSufficientFunds(fromAccount, event.amount());

        // Конвертация валюты
        BigDecimal convertedAmount;
        BigDecimal exchangeRate = event.exchangeRate();
        if (fromAccount.getCurrency() != toAccount.getCurrency()) {
            if (exchangeRate != null) {
                convertedAmount = event.amount().multiply(exchangeRate)
                        .setScale(4, java.math.RoundingMode.HALF_UP);
            } else {
                exchangeRate = exchangeRateService.getRate(fromAccount.getCurrency(), toAccount.getCurrency());
                convertedAmount = exchangeRateService.convert(event.amount(), fromAccount.getCurrency(), toAccount.getCurrency());
            }
        } else {
            convertedAmount = event.amount();
        }

        // Обновляем балансы
        fromAccount.setBalance(fromAccount.getBalance().subtract(event.amount()));
        toAccount.setBalance(toAccount.getBalance().add(convertedAmount));
        accountRepository.save(fromAccount);
        accountRepository.save(toAccount);

        // Создаём две операции
        UUID transferOutKey = event.idempotencyKey();
        UUID transferInKey = UUID.nameUUIDFromBytes(
                (event.idempotencyKey().toString() + "_IN").getBytes()
        );

        Operation outOperation = Operation.builder()
                .idempotencyKey(transferOutKey)
                .account(fromAccount)
                .type(OperationType.TRANSFER_OUT)
                .amount(event.amount())
                .currency(fromAccount.getCurrency())
                .relatedAccount(toAccount)
                .exchangeRate(exchangeRate)
                .description(event.description())
                .build();

        Operation inOperation = Operation.builder()
                .idempotencyKey(transferInKey)
                .account(toAccount)
                .type(OperationType.TRANSFER_IN)
                .amount(convertedAmount)
                .currency(toAccount.getCurrency())
                .relatedAccount(fromAccount)
                .exchangeRate(exchangeRate)
                .description("Перевод со счёта #" + fromId)
                .build();

        operationRepository.save(outOperation);
        operationRepository.save(inOperation);

        log.info("Перевод: {} {} {} -> {} {} {}, курс={}",
                fromId, event.amount(), fromAccount.getCurrency(),
                toId, convertedAmount, toAccount.getCurrency(),
                exchangeRate);

        notificationService.notifyNewOperation(OperationMapper.toResponse(outOperation));
        notificationService.notifyNewOperation(OperationMapper.toResponse(inOperation));
    }

    // --- Helper methods ---

    private Account findActiveAccount(Long accountId) {
        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new AccountNotFoundException(accountId));
        if (account.getIsClosed()) {
            throw new AccountClosedException(accountId);
        }
        return account;
    }

    private Account lockAccount(Long accountId) {
        return accountRepository.findByIdForUpdate(accountId)
                .orElseThrow(() -> new AccountNotFoundException(accountId));
    }

    private void validateAccountActive(Account account) {
        if (account.getIsClosed()) {
            throw new AccountClosedException(account.getId());
        }
    }

    private void validateSufficientFunds(Account account, BigDecimal amount) {
        if (account.getBalance().compareTo(amount) < 0) {
            throw new InsufficientFundsException(account.getId(), amount, account.getBalance());
        }
    }

    private Operation buildOperation(OperationEvent event, Account account, Account relatedAccount) {
        return Operation.builder()
                .idempotencyKey(event.idempotencyKey())
                .account(account)
                .type(event.type())
                .amount(event.amount())
                .currency(event.currency())
                .relatedAccount(relatedAccount)
                .exchangeRate(event.exchangeRate())
                .description(event.description())
                .build();
    }
}
