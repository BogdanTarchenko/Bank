package com.bank.core.dto;

import com.bank.core.model.Currency;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record MasterAccountTransferRequest(
        @NotNull Long targetAccountId,
        @NotNull @DecimalMin("0.01") BigDecimal amount,
        @NotNull Currency sourceCurrency
) {}
