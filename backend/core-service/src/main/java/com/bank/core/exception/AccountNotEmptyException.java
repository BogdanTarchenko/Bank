package com.bank.core.exception;

public class AccountNotEmptyException extends RuntimeException {

    public AccountNotEmptyException(Long id) {
        super("Невозможно закрыть счёт " + id + ": баланс не равен нулю");
    }
}
