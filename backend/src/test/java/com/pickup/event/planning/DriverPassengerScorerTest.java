package com.pickup.event.planning;

import com.pickup.common.geo.GeoPoint;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DriverPassengerScorerTest {

    private static final GeoPoint DESTINATION = new GeoPoint(0.0, 0.0);
    private static final Instant T0 = Instant.parse("2026-01-01T10:00:00Z");
    private static final Instant T1 = Instant.parse("2026-01-01T11:00:00Z");

    @Test
    void assignsPassengerToCloserDriverByTripStart() {
        UUID nearId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID farId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID passengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");

        EventParticipantEntity nearDriver =
                PlanningTestSupport.driver(nearId, T0, 0.0, 0.0, 4);
        EventParticipantEntity farDriver =
                PlanningTestSupport.driver(farId, T1, 2.0, 0.0, 4);
        EventParticipantEntity passenger =
                PlanningTestSupport.passenger(passengerId, T0, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(nearDriver, farDriver),
                List.of(passenger),
                DESTINATION);

        assertEquals(1, assignments.size());
        assertEquals(nearId, assignments.getFirst().driverParticipantId());
        assertEquals(List.of(passengerId), assignments.getFirst().passengerParticipantIds());
    }

    @Test
    void equidistantDrivers_prefersMoreRemainingCapacity() {
        UUID smallerCapacityId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID largerCapacityId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID passengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");

        EventParticipantEntity smallerCapacityDriver =
                PlanningTestSupport.driver(smallerCapacityId, T0, 0.0, 0.0, 3);
        EventParticipantEntity largerCapacityDriver =
                PlanningTestSupport.driver(largerCapacityId, T1, 0.0, 0.0, 6);
        EventParticipantEntity passenger =
                PlanningTestSupport.passenger(passengerId, T0, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(smallerCapacityDriver, largerCapacityDriver),
                List.of(passenger),
                DESTINATION);

        assertEquals(1, assignments.size());
        assertEquals(largerCapacityId, assignments.getFirst().driverParticipantId());
    }

    @Test
    void eachPassengerAssignedAtMostOnce_overflowStaysUnassigned() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID p1 = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID p2 = UUID.fromString("00000000-0000-0000-0000-000000000011");

        EventParticipantEntity driver = PlanningTestSupport.driver(driverId, T0, 0.0, 0.0, 2);
        EventParticipantEntity passenger1 = PlanningTestSupport.passenger(p1, T0, 0.1, 0.0);
        EventParticipantEntity passenger2 = PlanningTestSupport.passenger(p2, T1, 0.2, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driver),
                List.of(passenger1, passenger2),
                DESTINATION);

        assertEquals(1, assignments.size());
        assertEquals(1, assignments.getFirst().passengerParticipantIds().size());
        assertTrue(assignments.getFirst().passengerParticipantIds().contains(p1));
    }
}
