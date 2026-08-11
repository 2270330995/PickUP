package com.pickup.location.dto;

public record ResolvedPlaceResponse(
        String formattedAddress,
        double lat,
        double lng
) {}
