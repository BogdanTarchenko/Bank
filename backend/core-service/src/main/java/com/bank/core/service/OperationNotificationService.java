package com.bank.core.service;

import com.bank.core.config.KafkaConfig;
import com.bank.core.dto.OperationResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class OperationNotificationService {

    private final SimpMessagingTemplate messagingTemplate;
    private final OutboxEventService outboxEventService;

    public void notifyNewOperation(OperationResponse operation) {
        // WebSocket уведомление для прямых подключений к core-service
        String destination = "/topic/accounts/" + operation.accountId() + "/operations";
        log.debug("WebSocket уведомление: {} -> {}", destination, operation.type());
        messagingTemplate.convertAndSend(destination, operation);

        // Kafka уведомление для BFF-сервисов — сохраняем в outbox (в той же транзакции)
        log.info("Сохранение уведомления в outbox: accountId={}, type={}", operation.accountId(), operation.type());
        outboxEventService.save(KafkaConfig.OPERATION_NOTIFICATIONS_TOPIC,
                String.valueOf(operation.accountId()), operation);
    }
}
