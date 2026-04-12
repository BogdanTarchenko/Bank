package com.bank.employeebff.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class OperationNotificationConsumer {

    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;
    private final PushNotificationService pushNotificationService;

    @KafkaListener(topics = "bank.operation-notifications", groupId = "employee-bff")
    public void onOperationNotification(String message) {
        JsonNode node;
        try {
            node = objectMapper.readTree(message);
        } catch (JsonProcessingException e) {
            // Невалидный JSON — повторная попытка не поможет, пропускаем
            log.error("Невалидный JSON в уведомлении, сообщение пропущено: {}", e.getMessage());
            return;
        }

        Long accountId = node.get("accountId").asLong();
        String destination = "/topic/accounts/" + accountId + "/operations";
        log.info("Ретрансляция уведомления в WebSocket: {}", destination);
        // Исключение от WebSocket пробрасывается наверх → DefaultErrorHandler выполнит retry
        messagingTemplate.convertAndSend(destination, objectMapper.convertValue(node, Map.class));

        try {
            pushNotificationService.sendToAll("Новая операция",
                    "Выполнена операция по счёту " + accountId);
        } catch (Exception e) {
            log.warn("Ошибка отправки push-уведомления: {}", e.getMessage());
        }
    }
}
