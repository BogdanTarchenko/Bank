package com.bank.employeebff.repository;

import com.bank.employeebff.model.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    List<DeviceToken> findByUserId(Long userId);
    void deleteByUserIdAndFcmToken(Long userId, String fcmToken);
}
