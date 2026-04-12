package com.bank.credit.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Component
@Slf4j
public class MonitoringClient {

    private final RestClient restClient;
    private final String monitoringUrl;
    private final String serviceName;

    public MonitoringClient(
            RestClient.Builder restClientBuilder,
            @Value("${monitoring.url:http://localhost:8086}") String monitoringUrl,
            @Value("${spring.application.name}") String serviceName) {
        this.restClient = restClientBuilder.build();
        this.monitoringUrl = monitoringUrl;
        this.serviceName = serviceName;
    }

    @Async
    public void send(String traceId, String method, String path, int statusCode, long durationMs, String errorMessage) {
        try {
            Map<String, Object> payload = new HashMap<>();
            payload.put("type", statusCode >= 500 ? "ERROR" : "REQUEST_TRACE");
            payload.put("service", serviceName);
            payload.put("traceId", traceId);
            payload.put("recordedAt", LocalDateTime.now().toString());
            payload.put("durationMs", durationMs);
            payload.put("method", method);
            payload.put("path", path);
            payload.put("statusCode", statusCode);
            if (errorMessage != null) {
                payload.put("errorMessage", errorMessage);
            }
            restClient.post()
                    .uri(monitoringUrl + "/api/v1/metrics")
                    .header("Content-Type", "application/json")
                    .body(payload)
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            log.debug("Не удалось отправить метрику в monitoring-service: {}", e.getMessage());
        }
    }
}
