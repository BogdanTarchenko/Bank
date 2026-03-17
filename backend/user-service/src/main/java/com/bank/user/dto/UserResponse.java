package com.bank.user.dto;

import com.bank.user.model.Role;

import java.time.LocalDateTime;
import java.util.Set;

public record UserResponse(
        Long id,
        String email,
        String firstName,
        String lastName,
        String phone,
        boolean blocked,
        Set<Role> roles,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}
