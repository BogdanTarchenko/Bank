package com.bank.clientbff.controller;

import com.bank.clientbff.dto.DeviceTokenRequest;
import com.bank.clientbff.service.DeviceTokenService;
import com.bank.clientbff.service.UserResolverService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/device-tokens")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;
    private final UserResolverService userResolverService;

    @PostMapping
    public ResponseEntity<Void> register(@Valid @RequestBody DeviceTokenRequest request,
                                          @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        deviceTokenService.register(userId, request.fcmToken(), request.platform());
        return ResponseEntity.ok().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> unregister(@Valid @RequestBody DeviceTokenRequest request,
                                            @AuthenticationPrincipal Jwt jwt) {
        Long userId = userResolverService.resolveUserId(jwt);
        deviceTokenService.unregister(userId, request.fcmToken());
        return ResponseEntity.noContent().build();
    }
}
