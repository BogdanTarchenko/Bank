package com.bank.core.dto;

import com.bank.core.model.AccountType;
import com.bank.core.model.Currency;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record AccountResponse(
        Long id,
        Long userId,
        Currency currency,
        BigDecimal balance,
        AccountType accountType,
        Boolean isClosed,
        LocalDateTime createdAt
) {}
