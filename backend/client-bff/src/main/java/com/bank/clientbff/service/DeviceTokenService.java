package com.bank.clientbff.service;

import com.bank.clientbff.model.DeviceToken;
import com.bank.clientbff.repository.DeviceTokenRepository;
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
        boolean exists = deviceTokenRepository.findByUserId(userId).stream()
                .anyMatch(t -> t.getFcmToken().equals(fcmToken));
        if (exists) {
            log.debug("FCM-токен уже зарегистрирован для userId={}", userId);
            return;
        }
        deviceTokenRepository.save(DeviceToken.builder()
                .userId(userId)
                .fcmToken(fcmToken)
                .platform(platform)
                .build());
        log.info("FCM-токен зарегистрирован для userId={}", userId);
    }

    @Transactional
    public void unregister(Long userId, String fcmToken) {
        deviceTokenRepository.deleteByUserIdAndFcmToken(userId, fcmToken);
        log.info("FCM-токен удалён для userId={}", userId);
    }

    public List<String> getTokens(Long userId) {
        return deviceTokenRepository.findByUserId(userId).stream()
                .map(DeviceToken::getFcmToken)
                .toList();
    }
}
