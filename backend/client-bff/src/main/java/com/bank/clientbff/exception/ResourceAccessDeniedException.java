package com.bank.clientbff.exception;

public class ResourceAccessDeniedException extends RuntimeException {

    public ResourceAccessDeniedException(String resourceType) {
        super("Нет доступа к данному " + resourceType);
    }
}
