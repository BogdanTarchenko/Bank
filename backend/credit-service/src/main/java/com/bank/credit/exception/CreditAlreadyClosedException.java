package com.bank.credit.exception;

public class CreditAlreadyClosedException extends RuntimeException {
    public CreditAlreadyClosedException(Long id) {
        super("Кредит уже закрыт: id=" + id);
    }
}
