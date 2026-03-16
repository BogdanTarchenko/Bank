package com.bank.core.exception;

public class ExchangeRateUnavailableException extends RuntimeException {

    public ExchangeRateUnavailableException(String message) {
        super("Сервис курсов валют недоступен: " + message);
    }

    public ExchangeRateUnavailableException(String message, Throwable cause) {
        super("Сервис курсов валют недоступен: " + message, cause);
    }
}
