package com.bank.employeebff.dto;

import jakarta.validation.constraints.NotBlank;

public record DeviceTokenRequest(
        @NotBlank String fcmToken,
        @NotBlank String platform
) {
}
