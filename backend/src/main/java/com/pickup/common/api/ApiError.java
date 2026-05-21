package com.pickup.common.api;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        String code,
        String message,
        List<FieldViolation> fieldErrors,
        Map<String, Object> details
) {
    public static ApiError of(String code, String message) {
        return new ApiError(code, message, null, null);
    }

    public static ApiError of(String code, String message, List<FieldViolation> fieldErrors) {
        return new ApiError(code, message, fieldErrors, null);
    }

    public record FieldViolation(String field, String message) {}
}
