package com.pickup.event.planning;

import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DriverPassengerScorerTest {

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
                List.of(passenger));

        assertEquals(1, assignments.size());
        assertEquals(nearId, assignments.getFirst().driverParticipantId());
        assertEquals(List.of(passengerId), assignments.getFirst().passengerParticipantIds());
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
                List.of(passenger1, passenger2));

        assertEquals(1, assignments.size());
        assertEquals(1, assignments.getFirst().passengerParticipantIds().size());
        assertTrue(assignments.getFirst().passengerParticipantIds().contains(p1));
    }

    @Test
    void equidistantDrivers_tieBrokenByCreationOrder() {
        UUID earlierDriverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID laterDriverId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID passengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");

        // Same trip-start location for both drivers => distance to the passenger ties exactly.
        // Capacities differ (3 vs 6 seats) to prove the tie-break is creation order, not capacity.
        EventParticipantEntity earlierDriver =
                PlanningTestSupport.driver(earlierDriverId, T0, 0.0, 0.0, 3);
        EventParticipantEntity laterDriver =
                PlanningTestSupport.driver(laterDriverId, T1, 0.0, 0.0, 6);
        EventParticipantEntity passenger =
                PlanningTestSupport.passenger(passengerId, T0, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(laterDriver, earlierDriver), // deliberately out of creation order
                List.of(passenger));

        assertEquals(1, assignments.size());
        assertEquals(earlierDriverId, assignments.getFirst().driverParticipantId());
    }

    @Test
    void equidistantPassengers_tieBrokenByCreationOrder() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID earlierPassengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID laterPassengerId = UUID.fromString("00000000-0000-0000-0000-000000000011");

        // Only one seat, and both passengers sit at the exact same pickup point.
        EventParticipantEntity driver = PlanningTestSupport.driver(driverId, T0, 0.0, 0.0, 2);
        EventParticipantEntity earlierPassenger =
                PlanningTestSupport.passenger(earlierPassengerId, T0, 0.05, 0.0);
        EventParticipantEntity laterPassenger =
                PlanningTestSupport.passenger(laterPassengerId, T1, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driver),
                List.of(laterPassenger, earlierPassenger)); // deliberately out of creation order

        assertEquals(1, assignments.size());
        assertEquals(List.of(earlierPassengerId), assignments.getFirst().passengerParticipantIds());
    }

    @Test
    void globalSortFixesOrderDependentMisassignment() {
        // The motivating counterexample: a per-passenger greedy pass would let P1 (only
        // mildly closer to A than B) grab A's only seat, since it happens to be processed
        // first, stranding P2 (who is overwhelmingly closer to A) with the far driver B.
        // Sorting every pair globally instead lets P2's much cheaper (P2,A) pair win first.
        UUID driverAId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID driverBId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID p1Id = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID p2Id = UUID.fromString("00000000-0000-0000-0000-000000000011");

        EventParticipantEntity driverA = PlanningTestSupport.driver(driverAId, T0, 0.0, 0.0, 2);
        EventParticipantEntity driverB = PlanningTestSupport.driver(driverBId, T1, 2.0, 0.0, 2);
        // P1 processed first in a per-passenger scheme; only mildly prefers A (0.9 vs 1.1 away).
        EventParticipantEntity p1 = PlanningTestSupport.passenger(p1Id, T0, 0.9, 0.0);
        // P2 processed second; overwhelmingly prefers A (0.02 vs 1.98 away).
        EventParticipantEntity p2 = PlanningTestSupport.passenger(p2Id, T1, 0.02, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driverA, driverB),
                List.of(p1, p2));

        assertEquals(2, assignments.size());
        for (DriverAssignment assignment : assignments) {
            if (assignment.driverParticipantId().equals(driverAId)) {
                assertEquals(List.of(p2Id), assignment.passengerParticipantIds());
            } else {
                assertEquals(driverBId, assignment.driverParticipantId());
                assertEquals(List.of(p1Id), assignment.passengerParticipantIds());
            }
        }
    }

    @Test
    void knownLimitation_globalSortCanMissTrueOptimum() {
        // Documents an accepted trade-off, not a bug: this heuristic commits to the single
        // globally cheapest pair first, so it can still miss the true minimum-total-distance
        // assignment. Verified against the real Haversine DistanceCalculator (not just a flat
        // plane): (P1,A) is the smallest of the four distances, so greedy locks in P1->A
        // first, forcing P2->B — even though P1->B + P2->A is a strictly better total. A full
        // optimal solve would need a min-cost matching algorithm; this simpler algorithm was
        // deliberately chosen instead. See driver-passenger-matching-plan.md for the full
        // discussion.
        UUID driverAId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID driverBId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID p1Id = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID p2Id = UUID.fromString("00000000-0000-0000-0000-000000000011");

        EventParticipantEntity driverA = PlanningTestSupport.driver(driverAId, T0, 0.0, 0.0, 2);
        EventParticipantEntity driverB = PlanningTestSupport.driver(driverBId, T1, 1.0, 0.0, 2);
        EventParticipantEntity p1 = PlanningTestSupport.passenger(p1Id, T0, 0.4, 0.0);
        EventParticipantEntity p2 = PlanningTestSupport.passenger(p2Id, T1, 0.305, 0.396);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driverA, driverB),
                List.of(p1, p2));

        // The suboptimal-but-accepted result: P1 (the globally closest pair) grabs A first,
        // leaving P2 stuck with B, even though P1<->B / P2<->A would total less distance.
        assertEquals(2, assignments.size());
        for (DriverAssignment assignment : assignments) {
            if (assignment.driverParticipantId().equals(driverAId)) {
                assertEquals(List.of(p1Id), assignment.passengerParticipantIds());
            } else {
                assertEquals(driverBId, assignment.driverParticipantId());
                assertEquals(List.of(p2Id), assignment.passengerParticipantIds());
            }
        }
    }

    @Test
    void driverWithoutVehicle_neverReceivesAssignment() {
        UUID noVehicleDriverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID farDriverId = UUID.fromString("00000000-0000-0000-0000-000000000002");
        UUID passengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");

        // Positioned exactly on top of the passenger, but has no vehicle => zero capacity.
        EventParticipantEntity noVehicleDriver =
                PlanningTestSupport.driverWithoutVehicle(noVehicleDriverId, T0, 0.05, 0.0);
        EventParticipantEntity farDriver =
                PlanningTestSupport.driver(farDriverId, T1, 2.0, 0.0, 4);
        EventParticipantEntity passenger =
                PlanningTestSupport.passenger(passengerId, T0, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(noVehicleDriver, farDriver),
                List.of(passenger));

        assertEquals(1, assignments.size());
        assertEquals(farDriverId, assignments.getFirst().driverParticipantId());
    }

    @Test
    void driverWithoutTripStart_leavesPassengerUnassigned() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID passengerId = UUID.fromString("00000000-0000-0000-0000-000000000010");

        EventParticipantEntity driver =
                PlanningTestSupport.driverWithoutTripStart(driverId, T0, 4);
        EventParticipantEntity passenger =
                PlanningTestSupport.passenger(passengerId, T0, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driver),
                List.of(passenger));

        assertTrue(assignments.isEmpty());
    }

    @Test
    void noDrivers_returnsEmptyAssignments() {
        EventParticipantEntity passenger = PlanningTestSupport.passenger(
                UUID.fromString("00000000-0000-0000-0000-000000000010"), T0, 0.05, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(List.of(), List.of(passenger));

        assertTrue(assignments.isEmpty());
    }

    @Test
    void noPassengers_returnsEmptyAssignments() {
        EventParticipantEntity driver = PlanningTestSupport.driver(
                UUID.fromString("00000000-0000-0000-0000-000000000001"), T0, 0.0, 0.0, 4);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(List.of(driver), List.of());

        assertTrue(assignments.isEmpty());
    }

    @Test
    void allDriversFull_everyoneStaysUnassigned() {
        // seats=1 => capacity 0 (the seat is the driver's own).
        EventParticipantEntity driver1 = PlanningTestSupport.driver(
                UUID.fromString("00000000-0000-0000-0000-000000000001"), T0, 0.0, 0.0, 1);
        EventParticipantEntity driver2 = PlanningTestSupport.driver(
                UUID.fromString("00000000-0000-0000-0000-000000000002"), T1, 2.0, 0.0, 1);
        EventParticipantEntity p1 = PlanningTestSupport.passenger(
                UUID.fromString("00000000-0000-0000-0000-000000000010"), T0, 0.05, 0.0);
        EventParticipantEntity p2 = PlanningTestSupport.passenger(
                UUID.fromString("00000000-0000-0000-0000-000000000011"), T1, 1.95, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driver1, driver2), List.of(p1, p2));

        assertTrue(assignments.isEmpty());
    }

    @Test
    void multiSeatDriverTakesClosestPassengersUpToCapacity() {
        UUID driverId = UUID.fromString("00000000-0000-0000-0000-000000000001");
        UUID closeId = UUID.fromString("00000000-0000-0000-0000-000000000010");
        UUID midId = UUID.fromString("00000000-0000-0000-0000-000000000011");
        UUID farId = UUID.fromString("00000000-0000-0000-0000-000000000012");

        // seats=3 => capacity 2, but three passengers compete for those two seats.
        EventParticipantEntity driver = PlanningTestSupport.driver(driverId, T0, 0.0, 0.0, 3);
        EventParticipantEntity close = PlanningTestSupport.passenger(closeId, T0, 0.01, 0.0);
        EventParticipantEntity mid = PlanningTestSupport.passenger(midId, T1, 0.02, 0.0);
        EventParticipantEntity far = PlanningTestSupport.passenger(farId, T1.plusSeconds(1), 0.5, 0.0);

        List<DriverAssignment> assignments = DriverPassengerScorer.assign(
                List.of(driver), List.of(far, close, mid)); // deliberately out of distance order

        assertEquals(1, assignments.size());
        assertEquals(2, assignments.getFirst().passengerParticipantIds().size());
        assertTrue(assignments.getFirst().passengerParticipantIds().containsAll(List.of(closeId, midId)));
        assertFalse(assignments.getFirst().passengerParticipantIds().contains(farId));
    }
}
