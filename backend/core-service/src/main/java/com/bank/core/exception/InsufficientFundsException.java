package com.bank.core.exception;

import java.math.BigDecimal;

public class InsufficientFundsException extends RuntimeException {

    public InsufficientFundsException(Long accountId, BigDecimal requested, BigDecimal available) {
        super("Недостаточно средств на счёте " + accountId +
              ": запрошено " + requested + ", доступно " + available);
    }
}
