package com.bank.credit.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record RepayRequest(
        @NotNull(message = "Сумма погашения обязательна")
        @DecimalMin(value = "0.01", message = "Сумма должна быть положительной")
        BigDecimal amount
) {}
