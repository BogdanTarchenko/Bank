package com.bank.core.dto.kafka;

import com.bank.core.model.Currency;
import com.bank.core.model.OperationType;
import java.math.BigDecimal;
import java.util.UUID;

public record OperationEvent(
        UUID idempotencyKey,
        Long accountId,
        OperationType type,
        BigDecimal amount,
        Currency currency,
        Long relatedAccountId,
        BigDecimal exchangeRate,
        String description
) {}
