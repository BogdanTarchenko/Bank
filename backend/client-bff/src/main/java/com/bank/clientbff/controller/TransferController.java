package com.bank.clientbff.controller;

import com.bank.clientbff.exception.ResourceAccessDeniedException;
import com.bank.clientbff.service.CoreServiceClient;
import com.bank.clientbff.service.ResourceOwnershipService;
import com.bank.clientbff.service.UserResolverService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientResponseException;

@RestController
@RequestMapping("/api/v1/transfers")
@RequiredArgsConstructor
public class TransferController {

    private final CoreServiceClient coreServiceClient;
    private final UserResolverService userResolverService;
    private final ResourceOwnershipService ownershipService;
    private final ObjectMapper objectMapper;

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void transfer(@RequestBody String body,
                         @AuthenticationPrincipal Jwt jwt) {
        try {
            Long userId = userResolverService.resolveUserId(jwt);
            JsonNode request = objectMapper.readTree(body);
            long fromAccountId = request.get("fromAccountId").asLong();

            ownershipService.checkAccountOwnership(fromAccountId, userId);

            coreServiceClient.post("/api/v1/transfers", body);
        } catch (ResourceAccessDeniedException | RestClientResponseException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Ошибка выполнения перевода", e);
        }
    }
}
