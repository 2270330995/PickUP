package com.pickup.trip.dto;

import com.pickup.common.enums.TripStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Phase 1 placeholder. Populated in Phase 2 when trip execution is implemented.
 * Embeds {@link TripStopSummary} so callers get the full stop list without a separate request.
 */
public record TripResponse(
        UUID id,
        UUID eventId,
        UUID driverId,
        UUID vehicleId,
        TripStatus status,
        UUID currentStopId,
        String finalDestinationAddress,
        double finalDestinationLat,
        double finalDestinationLng,
        String encodedPolyline,
        Instant startedAt,
        Instant completedAt,
        List<TripStopSummary> stops
) {
    /** Embedded stop summary used inside TripResponse. */
    public record TripStopSummary(
            UUID id,
            int sequence,
            String address,
            String meetingPointName,
            double lat,
            double lng,
            com.pickup.common.enums.StopStatus status,
            Integer etaMinutes
    ) {}
}
