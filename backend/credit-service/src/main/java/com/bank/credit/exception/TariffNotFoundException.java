package com.bank.credit.exception;

public class TariffNotFoundException extends RuntimeException {
    public TariffNotFoundException(Long id) {
        super("Тариф не найден: id=" + id);
    }
}
