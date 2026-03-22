package com.bank.clientbff.controller;

import com.bank.clientbff.exception.ResourceAccessDeniedException;
import com.bank.clientbff.service.CreditServiceClient;
import com.bank.clientbff.service.ResourceOwnershipService;
import com.bank.clientbff.service.UserResolverService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientResponseException;

@RestController
@RequestMapping("/api/v1/credits")
@RequiredArgsConstructor
public class CreditController {

    private final CreditServiceClient creditServiceClient;
    private final UserResolverService userResolverService;
    private final ResourceOwnershipService ownershipService;
    private final ObjectMapper objectMapper;

    @GetMapping
    public ResponseEntity<String> getMyCredits(@AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        return creditServiceClient.get("/api/v1/credits?userId=" + userId);
    }

    @GetMapping("/{id}")
    public ResponseEntity<String> getCredit(@PathVariable Long id,
                                            @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkCreditOwnership(id, userId);
        return creditServiceClient.get("/api/v1/credits/" + id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ResponseEntity<String> createCredit(@RequestBody String body,
                                               @AuthenticationPrincipal Jwt jwt) {
        try {
            Long userId = userResolverService.resolveUserId(jwt);
            ObjectNode node = (ObjectNode) objectMapper.readTree(body);
            node.put("userId", userId);

            long accountId = node.get("accountId").asLong();
            ownershipService.checkAccountOwnership(accountId, userId);

            return creditServiceClient.post("/api/v1/credits", objectMapper.writeValueAsString(node));
        } catch (ResourceAccessDeniedException | RestClientResponseException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Ошибка создания кредита", e);
        }
    }

    @GetMapping("/{id}/payments")
    public ResponseEntity<String> getPayments(@PathVariable Long id,
                                              @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkCreditOwnership(id, userId);
        return creditServiceClient.get("/api/v1/credits/" + id + "/payments");
    }

    @PostMapping("/{id}/repay")
    public ResponseEntity<String> repayCredit(@PathVariable Long id,
                                              @RequestBody String body,
                                              @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkCreditOwnership(id, userId);
        return creditServiceClient.post("/api/v1/credits/" + id + "/repay", body);
    }
}
