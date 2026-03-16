package com.bank.core.service;

import com.bank.core.exception.ExchangeRateUnavailableException;
import com.bank.core.model.Currency;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class ExchangeRateClient {

    private final WebClient exchangeRateWebClient;

    @Cacheable(value = "exchangeRates", key = "#baseCurrency")
    public Map<String, BigDecimal> getRates(Currency baseCurrency) {
        log.info("Запрос курсов валют для базовой валюты: {}", baseCurrency);
        try {
            Map<String, Object> response = exchangeRateWebClient
                    .get()
                    .uri("/{base}", baseCurrency.name())
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();

            if (response == null || !"success".equals(response.get("result"))) {
                throw new ExchangeRateUnavailableException("Неуспешный ответ от API курсов валют");
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> rates = (Map<String, Object>) response.get("rates");
            if (rates == null) {
                throw new ExchangeRateUnavailableException("Отсутствуют данные о курсах в ответе");
            }

            return Map.of(
                    "RUB", toBigDecimal(rates.get("RUB")),
                    "USD", toBigDecimal(rates.get("USD")),
                    "EUR", toBigDecimal(rates.get("EUR"))
            );
        } catch (ExchangeRateUnavailableException e) {
            throw e;
        } catch (Exception e) {
            throw new ExchangeRateUnavailableException("Ошибка при запросе курсов валют", e);
        }
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value instanceof Number number) {
            return BigDecimal.valueOf(number.doubleValue());
        }
        throw new ExchangeRateUnavailableException("Некорректный формат курса валюты: " + value);
    }
}
