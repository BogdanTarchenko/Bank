package com.bank.employeebff.controller;

import com.bank.employeebff.dto.DeviceTokenRequest;
import com.bank.employeebff.service.DeviceTokenService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;

@RestController
@RequestMapping("/api/v1/device-tokens")
@Slf4j
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;
    private final RestClient restClient;
    private final String userServiceUrl;
    private final ObjectMapper objectMapper;

    public DeviceTokenController(
            DeviceTokenService deviceTokenService,
            RestClient.Builder restClientBuilder,
            @Value("${services.user-service.url}") String userServiceUrl,
            ObjectMapper objectMapper) {
        this.deviceTokenService = deviceTokenService;
        this.restClient = restClientBuilder.build();
        this.userServiceUrl = userServiceUrl;
        this.objectMapper = objectMapper;
    }

    @PostMapping
    public ResponseEntity<Void> registerToken(
            @Valid @RequestBody DeviceTokenRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = resolveUserId(jwt.getSubject());
        if (userId == null) {
            return ResponseEntity.internalServerError().build();
        }
        deviceTokenService.register(userId, request.fcmToken(), request.platform());
        return ResponseEntity.ok().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> unregisterToken(
            @Valid @RequestBody DeviceTokenRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = resolveUserId(jwt.getSubject());
        if (userId == null) {
            return ResponseEntity.internalServerError().build();
        }
        deviceTokenService.unregister(userId, request.fcmToken());
        return ResponseEntity.noContent().build();
    }

    private Long resolveUserId(String email) {
        try {
            String response = restClient.get()
                    .uri(userServiceUrl + "/api/v1/users/by-email?email=" + email)
                    .retrieve()
                    .body(String.class);
            return objectMapper.readTree(response).get("id").asLong();
        } catch (Exception e) {
            log.error("Ошибка получения пользователя по email {}: {}", email, e.getMessage());
            return null;
        }
    }
}
