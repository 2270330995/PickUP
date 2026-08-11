package com.pickup.participant.dto;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;

import java.time.Instant;
import java.util.UUID;

public record EventParticipantResponse(
        UUID id,
        UUID eventId,
        UUID userId,
        UUID contactId,
        String displayName,
        String displayEmail,
        String userFullName,
        String userEmail,
        ParticipantRole role,
        ParticipantStatus status,
        String pickupAddress,
        Double pickupLat,
        Double pickupLng,
        UUID vehicleId,
        VehicleSummary vehicleSummary,
        Instant createdAt
) {
    /**
     * Minimal vehicle detail inlined on participant responses so UIs can display
     * the driver's vehicle without a follow-up fetch. Null when the participant
     * has no vehicle attached.
     */
    public record VehicleSummary(
            UUID id,
            String make,
            String model,
            String color,
            String plate,
            int seats
    ) {}
}
