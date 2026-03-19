package com.bank.employeebff.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
@Slf4j
public class OperationNotificationConsumer {

    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;

    @KafkaListener(topics = "bank.operation-notifications", groupId = "employee-bff")
    public void onOperationNotification(String message) {
        try {
            log.info("Получено уведомление из Kafka: {}", message.substring(0, Math.min(message.length(), 200)));
            JsonNode node = objectMapper.readTree(message);
            Long accountId = node.get("accountId").asLong();
            String destination = "/topic/accounts/" + accountId + "/operations";
            log.info("Ретрансляция уведомления в WebSocket: {}", destination);
            // Отправляем как Map, чтобы MappingJackson2MessageConverter правильно сериализовал в JSON
            messagingTemplate.convertAndSend(destination, objectMapper.convertValue(node, java.util.Map.class));
        } catch (Exception e) {
            log.error("Ошибка обработки уведомления: {}", e.getMessage());
            log.error("Сырое сообщение: {}", message.substring(0, Math.min(message.length(), 500)));
        }
    }
}
