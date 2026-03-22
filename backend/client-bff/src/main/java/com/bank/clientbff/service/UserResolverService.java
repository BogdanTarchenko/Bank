package com.bank.clientbff.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
@Slf4j
public class UserResolverService {

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final String userServiceUrl;

    public UserResolverService(
            RestClient.Builder restClientBuilder,
            ObjectMapper objectMapper,
            @Value("${services.user-service.url}") String userServiceUrl) {
        this.restClient = restClientBuilder.build();
        this.objectMapper = objectMapper;
        this.userServiceUrl = userServiceUrl;
    }

    public Long resolveUserId(Jwt jwt) {
        String email = jwt.getSubject();
        try {
            String response = restClient.get()
                    .uri(userServiceUrl + "/api/v1/users/by-email?email=" + email)
                    .retrieve()
                    .body(String.class);
            JsonNode node = objectMapper.readTree(response);
            return node.get("id").asLong();
        } catch (Exception e) {
            log.error("Не удалось получить userId для {}: {}", email, e.getMessage());
            throw new RuntimeException("Не удалось определить пользователя", e);
        }
    }
}
