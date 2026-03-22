package com.bank.credit.service;

import com.bank.credit.exception.InsufficientFundsException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.math.BigDecimal;
import java.util.Map;

@Service
@Slf4j
public class CoreServiceClient {

    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

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
        } catch (RestClientResponseException e) {
            log.error("Ошибка перевода с мастер-счёта: {}", e.getMessage());
            throw new RuntimeException(extractMessage(e, "Не удалось выполнить перевод с мастер-счёта"), e);
        } catch (Exception e) {
            log.error("Ошибка перевода с мастер-счёта: {}", e.getMessage());
            throw new RuntimeException("Не удалось выполнить перевод с мастер-счёта", e);
        }
    }

    private RestClientResponseException findRestClientException(Throwable t) {
        Throwable current = t;
        while (current != null) {
            if (current instanceof RestClientResponseException rce) return rce;
            current = current.getCause();
        }
        return null;
    }

    private String extractMessage(RestClientResponseException e, String fallback) {
        try {
            JsonNode node = objectMapper.readTree(e.getResponseBodyAsString());
            JsonNode msg = node.get("message");
            return msg != null && !msg.isNull() ? msg.asText() : fallback;
        } catch (Exception ignored) {
            return fallback;
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
            RestClientResponseException rce = findRestClientException(e);
            if (rce != null && rce.getStatusCode().value() == 422) {
                throw new InsufficientFundsException(extractMessage(rce, "Недостаточно средств на счёте"));
            }
            throw new RuntimeException("Не удалось списать средства со счёта", e);
        }
    }
}
