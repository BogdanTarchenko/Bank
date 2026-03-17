package com.bank.auth.service;

import com.bank.auth.dto.RegisterRequest;
import com.bank.auth.exception.EmailAlreadyExistsException;
import com.bank.auth.model.AuthUser;
import com.bank.auth.repository.AuthUserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final AuthUserRepository authUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final RestClient.Builder restClientBuilder;

    @Value("${services.user-service.url}")
    private String userServiceUrl;

    @Transactional
    public void register(RegisterRequest request) {
        if (authUserRepository.existsByEmail(request.email())) {
            throw new EmailAlreadyExistsException(request.email());
        }

        AuthUser authUser = AuthUser.builder()
                .email(request.email())
                .passwordHash(passwordEncoder.encode(request.password()))
                .enabled(true)
                .build();
        authUserRepository.save(authUser);

        createUserInUserService(request);
    }

    private void createUserInUserService(RegisterRequest request) {
        Set<String> roles = request.roles() != null && !request.roles().isEmpty()
                ? request.roles()
                : Set.of("CLIENT");

        var body = Map.of(
                "email", request.email(),
                "firstName", request.firstName(),
                "lastName", request.lastName(),
                "phone", request.phone() != null ? request.phone() : "",
                "roles", roles
        );

        try {
            restClientBuilder.build()
                    .post()
                    .uri(userServiceUrl + "/api/v1/users")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Пользователь создан в user-service: {}", request.email());
        } catch (Exception e) {
            log.error("Ошибка создания пользователя в user-service: {}", e.getMessage());
            throw new RuntimeException("Не удалось создать профиль пользователя", e);
        }
    }
}
