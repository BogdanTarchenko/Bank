package com.bank.core.service;

import com.bank.core.config.KafkaConfig;
import com.bank.core.dto.OperationResponse;
import com.bank.core.dto.kafka.OperationEvent;
import com.bank.core.model.OutboxEvent;
import com.bank.core.model.OutboxEventStatus;
import com.bank.core.repository.OutboxEventRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class OutboxEventPublisher {

    private static final int BATCH_SIZE = 100;
    private static final int MAX_RETRIES = 10;

    private final OutboxEventRepository outboxEventRepository;
    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Scheduled(fixedDelay = 500)
    @Transactional
    public void publishPendingEvents() {
        List<OutboxEvent> pending = outboxEventRepository.findByStatusOrderByCreatedAtAsc(
                OutboxEventStatus.PENDING, PageRequest.of(0, BATCH_SIZE));

        if (pending.isEmpty()) {
            return;
        }

        log.debug("Outbox: найдено {} событий для отправки", pending.size());

        for (OutboxEvent event : pending) {
            try {
                Object payload = deserialize(event);
                kafkaTemplate.send(event.getTopic(), event.getEventKey(), payload)
                        .get(5, TimeUnit.SECONDS);
                event.setStatus(OutboxEventStatus.SENT);
                event.setSentAt(LocalDateTime.now());
                log.debug("Outbox: событие {} отправлено в топик {}", event.getId(), event.getTopic());
            } catch (Exception e) {
                int retries = event.getRetryCount() + 1;
                event.setRetryCount(retries);
                if (retries >= MAX_RETRIES) {
                    event.setStatus(OutboxEventStatus.FAILED);
                    log.error("Outbox: событие {} помечено как FAILED после {} попыток: {}",
                            event.getId(), retries, e.getMessage());
                } else {
                    log.warn("Outbox: ошибка отправки события {} (попытка {}/{}): {}",
                            event.getId(), retries, MAX_RETRIES, e.getMessage());
                }
            }
            outboxEventRepository.save(event);
        }
    }

    private Object deserialize(OutboxEvent event) throws Exception {
        return switch (event.getTopic()) {
            case KafkaConfig.OPERATIONS_TOPIC ->
                    objectMapper.readValue(event.getPayload(), OperationEvent.class);
            case KafkaConfig.OPERATION_NOTIFICATIONS_TOPIC ->
                    objectMapper.readValue(event.getPayload(), OperationResponse.class);
            default -> throw new IllegalArgumentException("Неизвестный топик: " + event.getTopic());
        };
    }
}
