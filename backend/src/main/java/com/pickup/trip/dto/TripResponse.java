package com.pickup.trip.dto;

import com.pickup.common.enums.NavigationTargetType;
import com.pickup.common.enums.StopStatus;
import com.pickup.common.enums.TripStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Read model for a trip, including the embedded ordered stop list and enough
 * denormalized context (driver/vehicle/event) that the driver and passenger
 * UIs can render without follow-up fetches.
 */
public record TripResponse(
        UUID id,
        UUID eventId,
        String eventTitle,
        Instant eventTime,
        UUID driverId,
        String driverFullName,
        UUID vehicleId,
        VehicleSummary vehicleSummary,
        TripStatus status,
        UUID currentStopId,
        String finalDestinationAddress,
        double finalDestinationLat,
        double finalDestinationLng,
        String encodedPolyline,
        Instant startedAt,
        Instant completedAt,
        List<TripStopSummary> stops,
        NavigationTargetType navigationTargetType,
        String navigationLabel,
        String navigationUrl
) {
    /** Minimal vehicle detail inlined on trip responses. */
    public record VehicleSummary(
            UUID id,
            String make,
            String model,
            String color,
            String plate,
            int seats
    ) {}

    /** Embedded stop summary used inside TripResponse. */
    public record TripStopSummary(
            UUID id,
            int sequence,
            UUID participantId,
            UUID userId,
            String userFullName,
            String address,
            String meetingPointName,
            double lat,
            double lng,
            StopStatus status,
            Integer etaMinutes,
            Instant actualArrivalTime,
            Instant actualDepartureTime
    ) {}
}
