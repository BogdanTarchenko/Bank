package com.bank.clientbff.controller;

import com.bank.clientbff.exception.ResourceAccessDeniedException;
import com.bank.clientbff.service.CoreServiceClient;
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
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final CoreServiceClient coreServiceClient;
    private final UserResolverService userResolverService;
    private final ResourceOwnershipService ownershipService;
    private final ObjectMapper objectMapper;

    @GetMapping
    public ResponseEntity<String> getMyAccounts(@AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        return coreServiceClient.get("/api/v1/accounts?userId=" + userId);
    }

    @GetMapping("/{id}")
    public ResponseEntity<String> getAccount(@PathVariable Long id,
                                             @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkAccountOwnership(id, userId);
        return coreServiceClient.get("/api/v1/accounts/" + id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ResponseEntity<String> createAccount(@RequestBody String body,
                                                @AuthenticationPrincipal Jwt jwt) {
        try {
            Long userId = userResolverService.resolveUserId(jwt);
            ObjectNode node = (ObjectNode) objectMapper.readTree(body);
            node.put("userId", userId);
            return coreServiceClient.post("/api/v1/accounts", objectMapper.writeValueAsString(node));
        } catch (ResourceAccessDeniedException | RestClientResponseException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Ошибка создания счёта", e);
        }
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void closeAccount(@PathVariable Long id,
                             @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkAccountOwnership(id, userId);
        coreServiceClient.delete("/api/v1/accounts/" + id);
    }

    @PostMapping("/{id}/deposit")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void deposit(@PathVariable Long id,
                        @RequestBody String body,
                        @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkAccountOwnership(id, userId);
        coreServiceClient.post("/api/v1/accounts/" + id + "/deposit", body);
    }

    @PostMapping("/{id}/withdraw")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void withdraw(@PathVariable Long id,
                         @RequestBody String body,
                         @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkAccountOwnership(id, userId);
        coreServiceClient.post("/api/v1/accounts/" + id + "/withdraw", body);
    }

    @GetMapping("/{id}/operations")
    public ResponseEntity<String> getOperations(@PathVariable Long id,
                                                @RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "20") int size,
                                                @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        ownershipService.checkAccountOwnership(id, userId);
        return coreServiceClient.get("/api/v1/accounts/" + id + "/operations?page=" + page + "&size=" + size);
    }
}
