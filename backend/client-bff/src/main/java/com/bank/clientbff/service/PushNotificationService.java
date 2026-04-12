package com.bank.clientbff.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PushNotificationService {

    private final DeviceTokenService deviceTokenService;

    public void sendToUser(Long userId, String title, String body) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("Firebase not initialized, skipping push notification");
            return;
        }
        List<String> tokens = deviceTokenService.getTokens(userId);
        if (tokens.isEmpty()) return;

        MulticastMessage message = MulticastMessage.builder()
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .addAllTokens(tokens)
                .build();
        try {
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("Push отправлен пользователю userId={}: {} успешно, {} ошибок",
                    userId, response.getSuccessCount(), response.getFailureCount());
        } catch (FirebaseMessagingException e) {
            log.error("Ошибка отправки push пользователю userId={}: {}", userId, e.getMessage());
        }
    }
}
