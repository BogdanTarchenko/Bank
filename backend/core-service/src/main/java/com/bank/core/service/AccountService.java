package com.bank.core.service;

import com.bank.core.dto.AccountResponse;
import com.bank.core.dto.CreateAccountRequest;
import com.bank.core.dto.mapper.AccountMapper;
import com.bank.core.exception.AccountClosedException;
import com.bank.core.exception.AccountNotEmptyException;
import com.bank.core.exception.AccountNotFoundException;
import com.bank.core.model.Account;
import com.bank.core.model.AccountType;
import com.bank.core.model.Currency;
import com.bank.core.repository.AccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AccountService {

    private final AccountRepository accountRepository;

    @Transactional
    public AccountResponse createAccount(CreateAccountRequest request) {
        Account account = AccountMapper.toEntity(request);
        Account saved = accountRepository.save(account);
        log.info("Создан счёт: id={}, userId={}, currency={}", saved.getId(), saved.getUserId(), saved.getCurrency());
        return AccountMapper.toResponse(saved);
    }

    @Transactional
    public void closeAccount(Long id) {
        Account account = findAccountOrThrow(id);

        if (account.getIsClosed()) {
            throw new AccountClosedException(id);
        }
        if (account.getBalance().compareTo(BigDecimal.ZERO) != 0) {
            throw new AccountNotEmptyException(id);
        }

        account.setIsClosed(true);
        accountRepository.save(account);
        log.info("Закрыт счёт: id={}", id);
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> getAccountsByUserId(Long userId) {
        return accountRepository.findByUserIdAndIsClosedFalse(userId).stream()
                .map(AccountMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> getAllAccounts() {
        return accountRepository.findByIsClosedFalse().stream()
                .map(AccountMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public AccountResponse getAccountById(Long id) {
        return AccountMapper.toResponse(findAccountOrThrow(id));
    }

    @Transactional(readOnly = true)
    public AccountResponse getMasterAccount(Currency currency) {
        Account master = accountRepository.findByAccountTypeAndCurrency(AccountType.MASTER, currency)
                .orElseThrow(() -> new AccountNotFoundException(-1L));
        return AccountMapper.toResponse(master);
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> getAllMasterAccounts() {
        return accountRepository.findAll().stream()
                .filter(a -> a.getAccountType() == AccountType.MASTER)
                .map(AccountMapper::toResponse)
                .toList();
    }

    private Account findAccountOrThrow(Long id) {
        return accountRepository.findById(id)
                .orElseThrow(() -> new AccountNotFoundException(id));
    }
}
