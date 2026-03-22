package com.bank.clientbff.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class CreditServiceClient {

    private final RestClient restClient;
    private final String creditServiceUrl;

    public CreditServiceClient(
            RestClient.Builder restClientBuilder,
            @Value("${services.credit-service.url}") String creditServiceUrl) {
        this.restClient = restClientBuilder.build();
        this.creditServiceUrl = creditServiceUrl;
    }

    public ResponseEntity<String> get(String path) {
        return restClient.get()
                .uri(creditServiceUrl + path)
                .retrieve()
                .toEntity(String.class);
    }

    public ResponseEntity<String> post(String path, String body) {
        return restClient.post()
                .uri(creditServiceUrl + path)
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .body(body)
                .retrieve()
                .toEntity(String.class);
    }
}
