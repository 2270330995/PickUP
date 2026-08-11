package com.pickup.vehicle.dto;

import java.time.Instant;
import java.util.UUID;

public record VehicleResponse(
        UUID id,
        UUID contactId,
        String label,
        String make,
        String model,
        String color,
        String plate,
        int seats,
        String notes,
        Instant createdAt
) {}
