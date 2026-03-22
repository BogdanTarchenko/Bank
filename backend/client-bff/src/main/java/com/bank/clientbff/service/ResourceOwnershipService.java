package com.bank.clientbff.service;

import com.bank.clientbff.exception.ResourceAccessDeniedException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ResourceOwnershipService {

    private final CoreServiceClient coreServiceClient;
    private final CreditServiceClient creditServiceClient;
    private final ObjectMapper objectMapper;

    public void checkAccountOwnership(Long accountId, Long userId) {
        String json = coreServiceClient.get("/api/v1/accounts/" + accountId).getBody();
        checkUserIdField(json, userId, "счёту");
    }

    public void checkCreditOwnership(Long creditId, Long userId) {
        String json = creditServiceClient.get("/api/v1/credits/" + creditId).getBody();
        checkUserIdField(json, userId, "кредиту");
    }

    private void checkUserIdField(String json, Long expectedUserId, String resourceType) {
        try {
            JsonNode node = objectMapper.readTree(json);
            long resourceUserId = node.get("userId").asLong();
            if (resourceUserId != expectedUserId) {
                throw new ResourceAccessDeniedException(resourceType);
            }
        } catch (ResourceAccessDeniedException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Ошибка проверки доступа", e);
        }
    }
}
