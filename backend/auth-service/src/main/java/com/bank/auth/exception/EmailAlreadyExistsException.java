package com.bank.auth.exception;

public class EmailAlreadyExistsException extends RuntimeException {
    public EmailAlreadyExistsException(String email) {
        super("Email уже зарегистрирован: " + email);
    }
}
