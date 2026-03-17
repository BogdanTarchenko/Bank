package com.bank.credit.exception;

public class CreditNotFoundException extends RuntimeException {
    public CreditNotFoundException(Long id) {
        super("Кредит не найден: id=" + id);
    }
}
