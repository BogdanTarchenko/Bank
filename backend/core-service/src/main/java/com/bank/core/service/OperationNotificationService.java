package com.bank.core.service;

import com.bank.core.config.KafkaConfig;
import com.bank.core.dto.OperationResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class OperationNotificationService {

    private final SimpMessagingTemplate messagingTemplate;
    private final KafkaTemplate<String, Object> kafkaTemplate;

    public void notifyNewOperation(OperationResponse operation) {
        // WebSocket уведомление для прямых подключений
        String destination = "/topic/accounts/" + operation.accountId() + "/operations";
        log.debug("WebSocket уведомление: {} -> {}", destination, operation.type());
        messagingTemplate.convertAndSend(destination, operation);

        // Kafka уведомление для BFF-сервисов (JsonSerializer сериализует объект напрямую)
        try {
            kafkaTemplate.send(KafkaConfig.OPERATION_NOTIFICATIONS_TOPIC,
                    String.valueOf(operation.accountId()), operation);
            log.info("Уведомление отправлено в Kafka: accountId={}, type={}", operation.accountId(), operation.type());
        } catch (Exception e) {
            log.error("Ошибка отправки уведомления в Kafka: {}", e.getMessage());
        }
    }
}
