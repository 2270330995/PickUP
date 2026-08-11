package com.pickup.event.planning;

import com.pickup.common.geo.GeoPoint;
import com.pickup.participant.EventParticipantEntity;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

class StopOrderPlannerTest {

    private static final GeoPoint DESTINATION = new GeoPoint(0.0, 0.0);
    private static final Instant T0 = Instant.parse("2026-01-01T10:00:00Z");
    private static final Instant T1 = Instant.parse("2026-01-01T11:00:00Z");
    private static final Instant T2 = Instant.parse("2026-01-01T12:00:00Z");

    @Test
    void nearestNeighborFromDriverTripStart_ordersByProximity() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID nearId = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID midId = UUID.fromString("00000000-0000-0000-0000-000000000011");
        UUID farId = UUID.fromString("00000000-0000-0000-0000-000000000012");

        EventParticipantEntity driver =
                PlanningTestSupport.driver(driverId, T0, 0.0, 0.0, 5);
        EventParticipantEntity near = PlanningTestSupport.passenger(nearId, T0, 0.1, 0.0);
        EventParticipantEntity mid = PlanningTestSupport.passenger(midId, T1, 0.2, 0.0);
        EventParticipantEntity far = PlanningTestSupport.passenger(farId, T2, 0.0, 0.2);

        Map<UUID, EventParticipantEntity> byId = mapOf(driver, near, mid, far);

        List<UUID> ordered = StopOrderPlanner.orderPassengerIds(
                driver,
                List.of(farId, midId, nearId),
                byId,
                DESTINATION);

        assertEquals(List.of(nearId, midId, farId), ordered);
    }

    @Test
    void reverseNearestNeighborFromDestination_ordersFarToNear() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID nearId = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID farId = UUID.fromString("00000000-0000-0000-0000-000000000011");

        EventParticipantEntity driver =
                PlanningTestSupport.driverWithoutTripStart(driverId, T0, 5);
        EventParticipantEntity near = PlanningTestSupport.passenger(nearId, T0, 0.1, 0.0);
        EventParticipantEntity far = PlanningTestSupport.passenger(farId, T1, 1.0, 0.0);

        Map<UUID, EventParticipantEntity> byId = mapOf(driver, near, far);

        List<UUID> ordered = StopOrderPlanner.orderPassengerIds(
                driver,
                List.of(nearId, farId),
                byId,
                DESTINATION);

        assertEquals(List.of(farId, nearId), ordered);
    }

    @Test
    void singleStop_preservesAssignmentOrder() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID passengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");

        EventParticipantEntity driver =
                PlanningTestSupport.driver(driverId, T0, 0.0, 0.0, 5);
        EventParticipantEntity passenger =
                PlanningTestSupport.passenger(passengerId, T0, 0.5, 0.5);

        Map<UUID, EventParticipantEntity> byId = mapOf(driver, passenger);

        List<UUID> ordered = StopOrderPlanner.orderPassengerIds(
                driver,
                List.of(passengerId),
                byId,
                DESTINATION);

        assertEquals(List.of(passengerId), ordered);
    }

    private static Map<UUID, EventParticipantEntity> mapOf(EventParticipantEntity... participants) {
        Map<UUID, EventParticipantEntity> byId = new LinkedHashMap<>();
        for (EventParticipantEntity participant : participants) {
            byId.put(participant.getId(), participant);
        }
        return byId;
    }
}
