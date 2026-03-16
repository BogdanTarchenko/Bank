package com.bank.core.service;

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

    public void notifyNewOperation(OperationResponse operation) {
        String destination = "/topic/accounts/" + operation.accountId() + "/operations";
        log.debug("WebSocket уведомление: {} -> {}", destination, operation.type());
        messagingTemplate.convertAndSend(destination, operation);
    }
}
