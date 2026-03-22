package com.bank.employeebff.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class RoleManagementService {

    private final RestClient.Builder restClientBuilder;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    @Value("${services.user-service.url}")
    private String userServiceUrl;

    public static final String ROLES_INVALIDATED_PREFIX = "roles:invalidated:";

    public ResponseEntity<String> updateRoles(Long targetUserId, String body, Jwt jwt) {
        String callerEmail = jwt.getSubject();

        Long callerUserId = getUserIdByEmail(callerEmail);
        if (callerUserId == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("{\"error\":\"Не удалось получить данные текущего пользователя\"}");
        }

        if (callerUserId.equals(targetUserId)) {
            try {
                JsonNode bodyNode = objectMapper.readTree(body);
                JsonNode rolesNode = bodyNode.get("roles");
                if (rolesNode != null) {
                    List<String> newRoles = new ArrayList<>();
                    rolesNode.forEach(r -> newRoles.add(r.asText()));
                    if (!newRoles.contains("EMPLOYEE")) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body("{\"error\":\"Сотрудник не может снять с себя роль EMPLOYEE\"}");
                    }
                }
            } catch (Exception e) {
                return ResponseEntity.badRequest().body("{\"error\":\"Некорректный формат запроса\"}");
            }
        }

        try {
            ResponseEntity<String> response = restClientBuilder.build()
                    .patch()
                    .uri(userServiceUrl + "/api/v1/users/" + targetUserId + "/roles")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + jwt.getTokenValue())
                    .body(body)
                    .retrieve()
                    .toEntity(String.class);

            String targetEmail = getUserEmailById(targetUserId);
            if (targetEmail != null) {
                String key = ROLES_INVALIDATED_PREFIX + targetEmail;
                redisTemplate.opsForValue().set(key, String.valueOf(Instant.now().getEpochSecond()), Duration.ofDays(30));
                log.info("Роли изменены для пользователя {}, токены инвалидированы", targetEmail);
            }

            return response;
        } catch (Exception e) {
            log.error("Ошибка обновления ролей для пользователя {}: {}", targetUserId, e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("{\"error\":\"Ошибка обновления ролей\"}");
        }
    }

    private Long getUserIdByEmail(String email) {
        try {
            String response = restClientBuilder.build()
                    .get()
                    .uri(userServiceUrl + "/api/v1/users/by-email?email=" + email)
                    .retrieve()
                    .body(String.class);
            return objectMapper.readTree(response).get("id").asLong();
        } catch (Exception e) {
            log.error("Ошибка получения пользователя по email {}: {}", email, e.getMessage());
            return null;
        }
    }

    private String getUserEmailById(Long userId) {
        try {
            String response = restClientBuilder.build()
                    .get()
                    .uri(userServiceUrl + "/api/v1/users/" + userId)
                    .retrieve()
                    .body(String.class);
            return objectMapper.readTree(response).get("email").asText();
        } catch (Exception e) {
            log.error("Ошибка получения email пользователя {}: {}", userId, e.getMessage());
            return null;
        }
    }
}
