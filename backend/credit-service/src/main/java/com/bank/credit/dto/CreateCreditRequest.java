package com.bank.credit.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record CreateCreditRequest(
        @NotNull(message = "ID пользователя обязателен")
        Long userId,

        @NotNull(message = "ID счёта обязателен")
        Long accountId,

        @NotNull(message = "ID тарифа обязателен")
        Long tariffId,

        @NotNull(message = "Сумма кредита обязательна")
        @DecimalMin(value = "1", message = "Сумма должна быть положительной")
        BigDecimal amount,

        @Min(value = 1, message = "Срок должен быть минимум 1 день")
        int termDays
) {}
