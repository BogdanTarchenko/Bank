package com.bank.user.exception;

public class UserBlockedException extends RuntimeException {
    public UserBlockedException(Long id) {
        super("Пользователь заблокирован: id=" + id);
    }
}
