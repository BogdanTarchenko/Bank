package com.bank.core.dto;

import com.bank.core.model.Currency;
import com.bank.core.model.OperationType;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record OperationResponse(
        Long id,
        Long accountId,
        OperationType type,
        BigDecimal amount,
        Currency currency,
        Long relatedAccountId,
        BigDecimal exchangeRate,
        String description,
        LocalDateTime createdAt
) {}
