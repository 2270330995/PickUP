package com.pickup.contact.dto;

import com.pickup.common.enums.ParticipantRole;
import jakarta.validation.constraints.Size;

/**
 * Partial update. All fields optional; a non-null string clears to null when blank
 * (mirrors {@code UpdateVehicleRequest} / {@code UpdateEventRequest} conventions).
 */
public record UpdateContactRequest(
        @Size(min = 1, max = 120) String name,
        @Size(max = 40) String phone,
        @Size(max = 160) String email,
        @Size(max = 240) String defaultAddress,
        Double defaultLat,
        Double defaultLng,
        @Size(max = 2000) String notes,
        ParticipantRole preferredRole
) {}
