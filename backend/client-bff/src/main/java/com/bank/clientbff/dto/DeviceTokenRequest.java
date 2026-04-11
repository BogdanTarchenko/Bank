package com.bank.clientbff.dto;

import jakarta.validation.constraints.NotBlank;

public record DeviceTokenRequest(
        @NotBlank String fcmToken,
        @NotBlank String platform
) {
}
