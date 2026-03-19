package com.bank.clientbff.service;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Service
@Slf4j
public class ProxyService {

    private final RestClient restClient;
    private final Map<String, String> serviceUrls;

    public ProxyService(
            RestClient.Builder restClientBuilder,
            @Value("${services.core-service.url}") String coreUrl,
            @Value("${services.user-service.url}") String userUrl,
            @Value("${services.credit-service.url}") String creditUrl) {
        this.restClient = restClientBuilder.build();
        this.serviceUrls = Map.of(
                "core", coreUrl,
                "user", userUrl,
                "credit", creditUrl
        );
    }

    public ResponseEntity<String> proxy(String serviceName, String path, HttpMethod method,
                                         String body, HttpServletRequest request) {
        String baseUrl = serviceUrls.get(serviceName);
        if (baseUrl == null) {
            return ResponseEntity.badRequest().body("{\"error\":\"Неизвестный сервис: " + serviceName + "\"}");
        }

        String targetUrl = baseUrl + "/api/v1" + path;
        String queryString = request.getQueryString();
        if (queryString != null) {
            targetUrl += "?" + queryString;
        }

        log.debug("Проксирование {} {} -> {}", method, path, targetUrl);

        var requestSpec = restClient.method(method)
                .uri(targetUrl)
                .header(HttpHeaders.CONTENT_TYPE, "application/json");

        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null) {
            requestSpec = requestSpec.header(HttpHeaders.AUTHORIZATION, authHeader);
        }

        if (body != null && !body.isBlank() && (method == HttpMethod.POST || method == HttpMethod.PUT || method == HttpMethod.PATCH)) {
            requestSpec = requestSpec.body(body);
        }

        try {
            return requestSpec.retrieve().toEntity(String.class);
        } catch (Exception e) {
            log.error("Ошибка проксирования: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("{\"error\":\"Ошибка связи с сервисом: " + serviceName + "\"}");
        }
    }
}
