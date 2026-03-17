package com.bank.user.dto;

import jakarta.validation.constraints.Email;

public record UpdateUserRequest(
        @Email(message = "Некорректный формат email")
        String email,

        String firstName,

        String lastName,

        String phone
) {}
