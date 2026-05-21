package com.pickup.common.api;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

/**
 * Utility for Phase 1 placeholder controllers. Every endpoint declared in the
 * Phase 1 plan exists so that the route surface compiles end-to-end, but
 * returns {@code 501 Not Implemented} via the global exception handler.
 */
public final class NotImplemented {

    private NotImplemented() {}

    public static <T> T phase1(String endpoint) {
        throw new ResponseStatusException(
                HttpStatus.NOT_IMPLEMENTED,
                "Phase 1 skeleton: '%s' is not implemented yet".formatted(endpoint)
        );
    }
}
