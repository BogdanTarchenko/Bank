package com.bank.credit.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.util.Map;

@Service
@Slf4j
public class CoreServiceClient {

    private final RestClient restClient;

    public CoreServiceClient(
            RestClient.Builder restClientBuilder,
            @Value("${services.core-service.url}") String coreServiceUrl) {
        this.restClient = restClientBuilder.baseUrl(coreServiceUrl).build();
    }

    public String getAccountCurrency(Long accountId) {
        try {
            var response = restClient.get()
                    .uri("/api/v1/accounts/{id}", accountId)
                    .retrieve()
                    .body(Map.class);
            if (response != null && response.containsKey("currency")) {
                return response.get("currency").toString();
            }
        } catch (Exception e) {
            log.error("Ошибка получения счёта {}: {}", accountId, e.getMessage());
            throw new RuntimeException("Не удалось получить данные счёта", e);
        }
        throw new RuntimeException("Счёт " + accountId + " не содержит валюту");
    }

    public void transferFromMasterAccount(Long targetAccountId, BigDecimal amount, String sourceCurrency) {
        var body = Map.of(
                "targetAccountId", targetAccountId,
                "amount", amount,
                "sourceCurrency", sourceCurrency
        );

        try {
            restClient.post()
                    .uri("/api/v1/master-account/transfer")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Перевод с мастер-счёта на счёт {}: {} {}", targetAccountId, amount, sourceCurrency);
        } catch (Exception e) {
            log.error("Ошибка перевода с мастер-счёта: {}", e.getMessage());
            throw new RuntimeException("Не удалось выполнить перевод с мастер-счёта", e);
        }
    }

    public void withdrawFromAccount(Long accountId, BigDecimal amount) {
        var body = Map.of("amount", amount);

        try {
            restClient.post()
                    .uri("/api/v1/accounts/{id}/withdraw", accountId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Списание со счёта {}: {}", accountId, amount);
        } catch (Exception e) {
            log.error("Ошибка списания со счёта {}: {}", accountId, e.getMessage());
            throw new RuntimeException("Не удалось списать средства со счёта", e);
        }
    }
}
