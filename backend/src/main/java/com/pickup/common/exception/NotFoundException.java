package com.pickup.common.exception;

import org.springframework.http.HttpStatus;

public class NotFoundException extends BaseException {

    public NotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, "NOT_FOUND", message);
    }

    public static NotFoundException of(String entity, Object id) {
        return new NotFoundException("%s not found: %s".formatted(entity, id));
    }
}
