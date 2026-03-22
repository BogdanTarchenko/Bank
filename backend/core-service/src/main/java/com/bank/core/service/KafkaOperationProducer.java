package com.bank.core.service;

import com.bank.core.config.KafkaConfig;
import com.bank.core.dto.kafka.OperationEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaOperationProducer {

    private final OutboxEventService outboxEventService;

    public void send(OperationEvent event) {
        String key = String.valueOf(event.accountId());
        log.info("Сохранение операции в outbox: topic={}, key={}, idempotencyKey={}",
                KafkaConfig.OPERATIONS_TOPIC, key, event.idempotencyKey());
        outboxEventService.save(KafkaConfig.OPERATIONS_TOPIC, key, event);
    }
}
