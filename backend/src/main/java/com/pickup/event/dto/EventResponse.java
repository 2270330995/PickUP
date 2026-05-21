package com.pickup.event.dto;

import com.pickup.common.enums.EventPlanningStatus;
import com.pickup.common.enums.EventStatus;

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
        Instant createdAt
) {}
