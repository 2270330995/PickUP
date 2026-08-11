package com.pickup.common.geo;

import com.pickup.participant.EventParticipantEntity;

import java.util.Optional;

/**
 * A WGS-84 coordinate pair used by routing-aware planning heuristics.
 */
public record GeoPoint(double lat, double lng) {

    /**
     * Driver trip start: for {@code DRIVER} participants, {@code pickupLat/Lng}
     * is where the driver begins the pickup route before the first passenger stop.
     */
    public static Optional<GeoPoint> tripStartFromDriver(EventParticipantEntity driver) {
        if (driver.getPickupLat() == null || driver.getPickupLng() == null) {
            return Optional.empty();
        }
        return Optional.of(new GeoPoint(driver.getPickupLat(), driver.getPickupLng()));
    }

    /** Passenger pickup location. */
    public static Optional<GeoPoint> pickupFromPassenger(EventParticipantEntity passenger) {
        if (passenger.getPickupLat() == null || passenger.getPickupLng() == null) {
            return Optional.empty();
        }
        return Optional.of(new GeoPoint(passenger.getPickupLat(), passenger.getPickupLng()));
    }
}
