package com.bank.credit.exception;

public class InvalidCreditAmountException extends RuntimeException {
    public InvalidCreditAmountException(String message) {
        super(message);
    }
}
