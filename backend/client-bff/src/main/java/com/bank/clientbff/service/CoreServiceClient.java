package com.bank.clientbff.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class CoreServiceClient {

    private final RestClient restClient;
    private final String coreServiceUrl;

    public CoreServiceClient(
            RestClient.Builder restClientBuilder,
            @Value("${services.core-service.url}") String coreServiceUrl) {
        this.restClient = restClientBuilder.build();
        this.coreServiceUrl = coreServiceUrl;
    }

    public ResponseEntity<String> get(String path) {
        return restClient.get()
                .uri(coreServiceUrl + path)
                .retrieve()
                .toEntity(String.class);
    }

    public ResponseEntity<String> post(String path, String body) {
        return restClient.post()
                .uri(coreServiceUrl + path)
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .body(body)
                .retrieve()
                .toEntity(String.class);
    }

    public void delete(String path) {
        restClient.delete()
                .uri(coreServiceUrl + path)
                .retrieve()
                .toBodilessEntity();
    }
}
