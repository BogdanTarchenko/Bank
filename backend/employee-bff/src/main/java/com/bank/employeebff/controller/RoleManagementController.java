package com.bank.employeebff.controller;

import com.bank.employeebff.service.RoleManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class RoleManagementController {

    private final RoleManagementService roleManagementService;

    @PatchMapping("/{id}/roles")
    public ResponseEntity<String> updateRoles(
            @PathVariable Long id,
            @RequestBody String body,
            @AuthenticationPrincipal Jwt jwt) {
        return roleManagementService.updateRoles(id, body, jwt);
    }
}
