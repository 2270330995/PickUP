package com.pickup.participant.dto;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;

import java.time.Instant;
import java.util.UUID;

public record EventParticipantResponse(
        UUID id,
        UUID eventId,
        UUID userId,
        String userFullName,
        String userEmail,
        ParticipantRole role,
        ParticipantStatus status,
        String pickupAddress,
        Double pickupLat,
        Double pickupLng,
        UUID vehicleId,
        Instant createdAt
) {}
