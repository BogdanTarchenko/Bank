package com.bank.credit.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record CreateTariffRequest(
        @NotBlank(message = "Название тарифа обязательно")
        String name,

        @NotNull(message = "Процентная ставка обязательна")
        @DecimalMin(value = "0.01", message = "Ставка должна быть положительной")
        BigDecimal interestRate,

        BigDecimal minAmount,
        BigDecimal maxAmount,

        @Min(value = 1, message = "Минимальный срок — 1 день")
        Integer minTermDays,

        Integer maxTermDays
) {}
