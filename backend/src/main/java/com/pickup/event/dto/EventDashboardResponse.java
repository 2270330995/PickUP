package com.pickup.event.dto;

import com.pickup.common.enums.EventPlanningStatus;
import com.pickup.common.enums.EventStatus;

import java.time.Instant;
import java.util.UUID;

public record EventDashboardResponse(
        UUID eventId,
        String title,
        Instant eventTime,
        EventStatus status,
        EventPlanningStatus planningStatus,
        Totals totals,
        Seats seats
) {
    public record Totals(
            int totalParticipants,
            int organizers,
            int confirmedDrivers,
            int passengersNeedingRides,
            int independentAttendees,
            int pendingRequests
    ) {}

    public record Seats(
            int totalSeatsAvailable,
            int seatsNeeded,
            int seatsSurplus,
            int driversMissingVehicle
    ) {}
}
