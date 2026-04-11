package com.bank.employeebff.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PushNotificationService {

    private final DeviceTokenService deviceTokenService;

    public void sendToAll(String title, String body) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("Firebase не инициализирован, push-уведомление пропущено");
            return;
        }
        List<String> tokens = deviceTokenService.getAllTokens();
        if (tokens.isEmpty()) {
            log.debug("Нет зарегистрированных FCM-токенов для отправки уведомлений");
            return;
        }
        MulticastMessage message = MulticastMessage.builder()
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .addAllTokens(tokens)
                .build();
        try {
            var response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("Push-уведомления отправлены: успешно={}, неуспешно={}",
                    response.getSuccessCount(), response.getFailureCount());
        } catch (Exception e) {
            log.error("Ошибка отправки push-уведомлений: {}", e.getMessage());
        }
    }
}
