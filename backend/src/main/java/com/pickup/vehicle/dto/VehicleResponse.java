package com.pickup.vehicle.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * Phase 1 placeholder. Populated in Phase 2 when vehicle CRUD is implemented.
 */
public record VehicleResponse(
        UUID id,
        UUID ownerId,
        String make,
        String model,
        String color,
        String plate,
        int seats,
        Instant createdAt
) {}
