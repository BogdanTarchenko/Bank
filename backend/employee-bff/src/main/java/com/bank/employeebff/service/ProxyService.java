package com.bank.employeebff.service;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryRegistry;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;
import java.util.function.Supplier;
import java.util.regex.Pattern;

@Service
@Slf4j
public class ProxyService {

    private final RestClient restClient;
    private final Map<String, String> serviceUrls;
    private final CircuitBreaker circuitBreaker;
    private final Retry retry;

    public ProxyService(
            RestClient.Builder restClientBuilder,
            @Value("${services.core-service.url}") String coreUrl,
            @Value("${services.user-service.url}") String userUrl,
            @Value("${services.credit-service.url}") String creditUrl,
            CircuitBreakerRegistry circuitBreakerRegistry,
            RetryRegistry retryRegistry) {
        this.restClient = restClientBuilder.build();
        this.serviceUrls = Map.of(
                "core", coreUrl,
                "user", userUrl,
                "credit", creditUrl
        );
        this.circuitBreaker = circuitBreakerRegistry.circuitBreaker("backendServices");
        this.retry = retryRegistry.retry("backendServices");
    }

    private static final Pattern ROLES_PATH = Pattern.compile("^/users/\\d+/roles$");

    public ResponseEntity<String> proxy(String serviceName, String path, HttpMethod method,
                                         String body, HttpServletRequest request) {
        String baseUrl = serviceUrls.get(serviceName);
        if (baseUrl == null) {
            return ResponseEntity.badRequest().body("{\"error\":\"Неизвестный сервис: " + serviceName + "\"}");
        }

        if ("user".equals(serviceName) && method == HttpMethod.PATCH && ROLES_PATH.matcher(path).matches()) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                    .body("{\"error\":\"Для управления ролями используйте PATCH /api/v1/users/{id}/roles\"}");
        }

        String targetUrl = baseUrl + "/api/v1" + path;
        String queryString = request.getQueryString();
        if (queryString != null) {
            targetUrl += "?" + queryString;
        }

        log.debug("Проксирование {} {} -> {}", method, path, targetUrl);

        final String finalTargetUrl = targetUrl;
        var requestSpec = restClient.method(method)
                .uri(finalTargetUrl)
                .header(HttpHeaders.CONTENT_TYPE, "application/json");

        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null) {
            requestSpec = requestSpec.header(HttpHeaders.AUTHORIZATION, authHeader);
        }

        if (body != null && !body.isBlank() && (method == HttpMethod.POST || method == HttpMethod.PUT || method == HttpMethod.PATCH)) {
            requestSpec = requestSpec.body(body);
        }

        final var finalRequestSpec = requestSpec;
        Supplier<ResponseEntity<String>> supplier = CircuitBreaker.decorateSupplier(
                circuitBreaker,
                Retry.decorateSupplier(retry, () -> finalRequestSpec.retrieve().toEntity(String.class))
        );

        try {
            return supplier.get();
        } catch (Exception e) {
            log.error("Ошибка проксирования: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("{\"error\":\"Ошибка связи с сервисом: " + serviceName + "\"}");
        }
    }
}
