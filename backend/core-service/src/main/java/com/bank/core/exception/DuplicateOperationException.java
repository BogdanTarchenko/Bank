package com.bank.core.exception;

import java.util.UUID;

public class DuplicateOperationException extends RuntimeException {

    public DuplicateOperationException(UUID idempotencyKey) {
        super("Операция с ключом " + idempotencyKey + " уже обработана");
    }
}
