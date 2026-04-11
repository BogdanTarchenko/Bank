package com.bank.clientbff.repository;

import com.bank.clientbff.model.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    List<DeviceToken> findByUserId(Long userId);

    @Transactional
    void deleteByUserIdAndFcmToken(Long userId, String fcmToken);
}
