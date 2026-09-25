package com.pickup.event.planning;

import com.pickup.common.geo.DistanceCalculator;
import com.pickup.common.geo.GeoPoint;
import com.pickup.common.geo.routing.RouteDistanceMeter;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.vehicle.VehicleEntity;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Global-distance-sort driver-passenger matching.
 *
 * <p>For {@code DRIVER} participants, {@code pickupLat/Lng} is interpreted as the driver's
 * trip start location (where the route begins before the first passenger stop).
 *
 * <p>Every eligible (driver, passenger) pair is scored by distance, sorted ascending, and
 * consumed greedily: the cheapest pair is assigned first, skipping any pair whose passenger
 * is already assigned or whose driver is already full. This avoids the failure mode of a
 * per-passenger greedy pass (assign each passenger to its own best driver, processed in a
 * fixed order), where an earlier-processed passenger can claim a seat that a later-processed
 * passenger needed far more, even though the earlier passenger would have been nearly as well
 * off with a different driver.
 *
 * <p>This is a known, accepted trade-off, not a guarantee of the true minimum-total-distance
 * assignment: because it commits to the single globally cheapest pair first, it can still lock
 * in a pairing that blocks a strictly better overall total in some cases (see
 * {@code DriverPassengerScorerTest#knownLimitation_globalSortCanMissTrueOptimum} for a worked
 * example). A full optimal solve would require a min-cost matching algorithm; this simpler
 * heuristic was chosen deliberately over that added complexity.
 */
public final class DriverPassengerScorer {

    private DriverPassengerScorer() {}

    /**
     * Assign each passenger to the best-scoring eligible driver with remaining capacity.
     */
    public static List<DriverAssignment> assign(
            List<EventParticipantEntity> drivers,
            List<EventParticipantEntity> passengers) {
        return assign(drivers, passengers, DistanceCalculator::distanceMeters);
    }

    public static List<DriverAssignment> assign(
            List<EventParticipantEntity> drivers,
            List<EventParticipantEntity> passengers,
            RouteDistanceMeter distanceMeter) {
        Map<UUID, Integer> remainingCapacity = new LinkedHashMap<>();
        for (EventParticipantEntity driver : drivers) {
            VehicleEntity vehicle = driver.getVehicle();
            int maxPassengers = vehicle == null ? 0 : Math.max(0, vehicle.getSeats() - 1);
            remainingCapacity.put(driver.getId(), maxPassengers);
        }

        Map<UUID, List<UUID>> assignedByDriver = new LinkedHashMap<>();
        for (EventParticipantEntity driver : drivers) {
            assignedByDriver.put(driver.getId(), new ArrayList<>());
        }

        List<CandidatePair> candidates = buildSortedCandidates(drivers, passengers, distanceMeter, remainingCapacity);

        Set<UUID> assignedPassengerIds = new HashSet<>();
        for (CandidatePair candidate : candidates) {
            UUID driverId = candidate.driver().getId();
            UUID passengerId = candidate.passenger().getId();
            if (assignedPassengerIds.contains(passengerId)) {
                continue; // already matched to a cheaper driver earlier in the sorted list
            }
            if (remainingCapacity.getOrDefault(driverId, 0) <= 0) {
                continue; // driver already full
            }
            assignedByDriver.get(driverId).add(passengerId);
            remainingCapacity.merge(driverId, -1, Integer::sum);
            assignedPassengerIds.add(passengerId);
        }

        List<DriverAssignment> result = new ArrayList<>();
        for (EventParticipantEntity driver : drivers) {
            List<UUID> passengerIds = assignedByDriver.get(driver.getId());
            if (!passengerIds.isEmpty()) {
                result.add(new DriverAssignment(driver.getId(), List.copyOf(passengerIds)));
            }
        }
        return result;
    }

    /**
     * Builds every (driver, passenger) pair worth considering — excluding drivers with no
     * remaining capacity or unknown trip-start location — sorted by distance ascending. Ties
     * are broken deterministically by driver then passenger creation order, encoded directly
     * in the comparator so it survives refactors of the loop structure above.
     */
    private static List<CandidatePair> buildSortedCandidates(
            List<EventParticipantEntity> drivers,
            List<EventParticipantEntity> passengers,
            RouteDistanceMeter distanceMeter,
            Map<UUID, Integer> remainingCapacity) {

        List<CandidatePair> candidates = new ArrayList<>();
        for (EventParticipantEntity driver : drivers) {
            if (remainingCapacity.getOrDefault(driver.getId(), 0) <= 0) {
                continue; // no seats to offer at all (no vehicle, or seats <= 1)
            }
            Optional<GeoPoint> tripStart = GeoPoint.tripStartFromDriver(driver);
            if (tripStart.isEmpty()) {
                continue; // unknown location; can never be matched
            }
            for (EventParticipantEntity passenger : passengers) {
                GeoPoint pickup = GeoPoint.pickupFromPassenger(passenger).orElseThrow();
                double distance = distanceMeter.distanceMeters(tripStart.get(), pickup);
                candidates.add(new CandidatePair(distance, driver, passenger));
            }
        }

        candidates.sort(
                Comparator.comparingDouble(CandidatePair::distanceMeters)
                        .thenComparing(CandidatePair::driver, participantOrder())
                        .thenComparing(CandidatePair::passenger, participantOrder()));
        return candidates;
    }

    private record CandidatePair(double distanceMeters, EventParticipantEntity driver, EventParticipantEntity passenger) {}

    private static Comparator<EventParticipantEntity> participantOrder() {
        return Comparator
                .comparing(EventParticipantEntity::getCreatedAt)
                .thenComparing(EventParticipantEntity::getId);
    }
}
