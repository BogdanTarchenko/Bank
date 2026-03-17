package com.bank.credit.dto;

import com.bank.credit.model.PaymentStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record PaymentResponse(
        Long id,
        Long creditId,
        BigDecimal amount,
        PaymentStatus status,
        LocalDateTime dueDate,
        LocalDateTime paidAt
) {}
