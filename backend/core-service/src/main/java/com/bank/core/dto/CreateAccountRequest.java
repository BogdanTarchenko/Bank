package com.bank.core.dto;

import com.bank.core.model.Currency;
import jakarta.validation.constraints.NotNull;

public record CreateAccountRequest(
        @NotNull Long userId,
        @NotNull Currency currency
) {}
