package com.pickup.location.dto;

import jakarta.validation.constraints.NotBlank;

public record ResolvePlaceRequest(
        String placeId,
        @NotBlank String query,
        String sessionToken
) {}
