package com.bank.user.dto;

import com.bank.user.model.Role;
import jakarta.validation.constraints.NotEmpty;

import java.util.Set;

public record UpdateRolesRequest(
        @NotEmpty(message = "Должна быть указана хотя бы одна роль")
        Set<Role> roles
) {}
