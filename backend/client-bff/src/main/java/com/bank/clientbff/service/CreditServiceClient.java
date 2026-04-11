package com.bank.clientbff.service;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryRegistry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
@Slf4j
public class CreditServiceClient {

    private final RestClient restClient;
    private final String creditServiceUrl;
    private final CircuitBreaker circuitBreaker;
    private final Retry retry;

    public CreditServiceClient(
            RestClient.Builder restClientBuilder,
            @Value("${services.credit-service.url}") String creditServiceUrl,
            CircuitBreakerRegistry circuitBreakerRegistry,
            RetryRegistry retryRegistry) {
        this.restClient = restClientBuilder.build();
        this.creditServiceUrl = creditServiceUrl;
        this.circuitBreaker = circuitBreakerRegistry.circuitBreaker("backendServices");
        this.retry = retryRegistry.retry("backendServices");
    }

    public ResponseEntity<String> get(String path) {
        return Retry.decorateSupplier(retry,
                CircuitBreaker.decorateSupplier(circuitBreaker,
                        () -> restClient.get()
                                .uri(creditServiceUrl + path)
                                .retrieve()
                                .toEntity(String.class)
                )).get();
    }

    public ResponseEntity<String> post(String path, String body) {
        return Retry.decorateSupplier(retry,
                CircuitBreaker.decorateSupplier(circuitBreaker,
                        () -> restClient.post()
                                .uri(creditServiceUrl + path)
                                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                                .body(body)
                                .retrieve()
                                .toEntity(String.class)
                )).get();
    }
}
