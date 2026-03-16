package com.bank.core.service;

import com.bank.core.dto.kafka.OperationEvent;
import com.bank.core.exception.AccountClosedException;
import com.bank.core.exception.AccountNotFoundException;
import com.bank.core.exception.ExchangeRateUnavailableException;
import com.bank.core.exception.InsufficientFundsException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaOperationConsumer {

    private final OperationService operationService;

    @KafkaListener(topics = "bank.operations", groupId = "core-service")
    public void consume(OperationEvent event) {
        log.info("Получено событие из Kafka: type={}, idempotencyKey={}", event.type(), event.idempotencyKey());
        try {
            operationService.processOperation(event);
        } catch (InsufficientFundsException e) {
            // Бизнес-ошибка: повторная обработка не поможет
            log.warn("Недостаточно средств для операции {}: {}", event.idempotencyKey(), e.getMessage());
        } catch (AccountNotFoundException e) {
            // Бизнес-ошибка: счёт не существует
            log.warn("Счёт не найден для операции {}: {}", event.idempotencyKey(), e.getMessage());
        } catch (AccountClosedException e) {
            // Бизнес-ошибка: счёт закрыт
            log.warn("Счёт закрыт для операции {}: {}", event.idempotencyKey(), e.getMessage());
        } catch (ExchangeRateUnavailableException e) {
            // Транзиентная ошибка: повторить обработку
            log.error("Сервис курсов валют недоступен для операции {}", event.idempotencyKey());
            throw e;
        }
    }
}
