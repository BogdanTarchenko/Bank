package com.bank.core.exception;

public class AccountNotFoundException extends RuntimeException {

    public AccountNotFoundException(Long id) {
        super("Счёт с id " + id + " не найден");
    }
}
