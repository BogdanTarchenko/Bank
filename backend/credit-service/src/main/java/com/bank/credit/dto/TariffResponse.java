package com.bank.credit.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record TariffResponse(
        Long id,
        String name,
        String currency,
        BigDecimal interestRate,
        BigDecimal minAmount,
        BigDecimal maxAmount,
        int minTermDays,
        int maxTermDays,
        boolean active,
        LocalDateTime createdAt
) {}
