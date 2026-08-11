package com.pickup.common.exception;

import org.springframework.http.HttpStatus;

public class BadRequestException extends BaseException {

    public BadRequestException(String message) {
        super(HttpStatus.BAD_REQUEST, "BAD_REQUEST", message);
    }
}
