package com.pickup.contact.dto;

import com.pickup.common.enums.ParticipantRole;

import java.time.Instant;
import java.util.UUID;

/**
 * Read model for an organizer-owned Contact, including a denormalized vehicle
 * count so the People list can render without a follow-up fetch per contact.
 */
public record ContactResponse(
        UUID id,
        String name,
        String phone,
        String email,
        String defaultAddress,
        Double defaultLat,
        Double defaultLng,
        String notes,
        ParticipantRole preferredRole,
        int vehicleCount,
        Instant archivedAt,
        Instant createdAt,
        Instant updatedAt
) {}
