package com.pickup.event.dto;

import com.pickup.common.enums.EventPlanningStatus;
import com.pickup.common.enums.EventStatus;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;

import java.time.Instant;
import java.util.UUID;

public record EventResponse(
        UUID id,
        UUID organizerId,
        String organizerName,
        String title,
        String description,
        String destinationAddress,
        double destinationLat,
        double destinationLng,
        Instant eventTime,
        EventStatus status,
        EventPlanningStatus planningStatus,
        boolean assignmentGenerated,
        int participantCount,
        // The current viewer's participant role/status for this event,
        // when known (e.g. on /events?scope=joined or /events/{id}).
        // Null for endpoints that don't resolve a viewer-specific row
        // (or when the viewer has no participant row).
        ParticipantRole currentUserParticipantRole,
        ParticipantStatus currentUserParticipantStatus,
        Instant createdAt
) {}
