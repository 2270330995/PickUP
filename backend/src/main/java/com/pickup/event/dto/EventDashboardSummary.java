package com.pickup.event.dto;

import com.pickup.common.enums.EventStatus;

import java.time.Instant;
import java.util.UUID;

public record EventDashboardSummary(
        UUID eventId,
        String title,
        Instant eventTime,
        EventStatus status,
        int totalParticipants,
        int confirmedDrivers,
        int pendingRequests,
        int seatsNeeded
) {}
