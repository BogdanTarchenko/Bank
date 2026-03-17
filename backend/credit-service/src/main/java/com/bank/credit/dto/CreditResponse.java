package com.bank.credit.dto;

import com.bank.credit.model.CreditStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record CreditResponse(
        Long id,
        Long userId,
        Long accountId,
        Long tariffId,
        String tariffName,
        BigDecimal principal,
        BigDecimal remaining,
        BigDecimal interestRate,
        int termDays,
        BigDecimal dailyPayment,
        CreditStatus status,
        LocalDateTime createdAt,
        LocalDateTime closedAt
) {}
