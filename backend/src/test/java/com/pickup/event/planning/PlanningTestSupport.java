package com.pickup.event.planning;

import com.pickup.common.domain.BaseEntity;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.vehicle.VehicleEntity;

import java.time.Instant;
import java.util.UUID;

final class PlanningTestSupport {

    private PlanningTestSupport() {}

    static EventParticipantEntity driver(
            UUID id,
            Instant createdAt,
            double tripStartLat,
            double tripStartLng,
            int vehicleSeats) {
        EventParticipantEntity driver = EventParticipantEntity.builder()
                .id(id)
                .role(ParticipantRole.DRIVER)
                .status(ParticipantStatus.CONFIRMED)
                .pickupAddress("Driver trip start")
                .pickupLat(tripStartLat)
                .pickupLng(tripStartLng)
                .vehicle(VehicleEntity.builder().seats(vehicleSeats).build())
                .build();
        setCreatedAt(driver, createdAt);
        return driver;
    }

    static EventParticipantEntity driverWithoutTripStart(
            UUID id, Instant createdAt, int vehicleSeats) {
        EventParticipantEntity driver = EventParticipantEntity.builder()
                .id(id)
                .role(ParticipantRole.DRIVER)
                .status(ParticipantStatus.CONFIRMED)
                .vehicle(VehicleEntity.builder().seats(vehicleSeats).build())
                .build();
        setCreatedAt(driver, createdAt);
        return driver;
    }

    static EventParticipantEntity passenger(
            UUID id, Instant createdAt, double pickupLat, double pickupLng) {
        EventParticipantEntity passenger = EventParticipantEntity.builder()
                .id(id)
                .role(ParticipantRole.PASSENGER)
                .status(ParticipantStatus.CONFIRMED)
                .pickupAddress("Pickup")
                .pickupLat(pickupLat)
                .pickupLng(pickupLng)
                .build();
        setCreatedAt(passenger, createdAt);
        return passenger;
    }

    private static void setCreatedAt(EventParticipantEntity entity, Instant createdAt) {
        try {
            var field = BaseEntity.class.getDeclaredField("createdAt");
            field.setAccessible(true);
            field.set(entity, createdAt);
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException(e);
        }
    }
}
