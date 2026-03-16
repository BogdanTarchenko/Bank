package com.bank.core.exception;

public class AccountClosedException extends RuntimeException {

    public AccountClosedException(Long id) {
        super("Счёт с id " + id + " закрыт");
    }
}
