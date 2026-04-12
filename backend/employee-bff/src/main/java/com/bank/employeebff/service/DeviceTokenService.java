package com.bank.employeebff.service;

import com.bank.employeebff.model.DeviceToken;
import com.bank.employeebff.repository.DeviceTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceTokenService {

    private final DeviceTokenRepository deviceTokenRepository;

    @Transactional
    public void register(Long userId, String fcmToken, String platform) {
        boolean exists = deviceTokenRepository.findByUserId(userId)
                .stream()
                .anyMatch(dt -> dt.getFcmToken().equals(fcmToken));
        if (!exists) {
            DeviceToken token = DeviceToken.builder()
                    .userId(userId)
                    .fcmToken(fcmToken)
                    .platform(platform)
                    .build();
            deviceTokenRepository.save(token);
            log.info("Зарегистрирован FCM-токен для пользователя {}", userId);
        }
    }

    @Transactional
    public void unregister(Long userId, String fcmToken) {
        deviceTokenRepository.deleteByUserIdAndFcmToken(userId, fcmToken);
        log.info("Удалён FCM-токен для пользователя {}", userId);
    }

    @Transactional(readOnly = true)
    public List<String> getAllTokens() {
        return deviceTokenRepository.findAll()
                .stream()
                .map(DeviceToken::getFcmToken)
                .toList();
    }
}
