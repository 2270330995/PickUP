package com.pickup.event.planning;

import com.pickup.common.geo.DistanceCalculator;
import com.pickup.common.geo.GeoPoint;
import com.pickup.common.geo.routing.RouteDistanceMeter;
import com.pickup.participant.EventParticipantEntity;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Deterministic intra-trip stop ordering after passengers are assigned to a driver.
 *
 * <p>For {@code DRIVER} participants, {@code pickupLat/Lng} is the trip start anchor
 * for nearest-neighbor ordering when present.
 */
public final class StopOrderPlanner {

    private StopOrderPlanner() {}

    /**
     * Reorder passenger IDs for pickup sequence. Does not mutate the input list.
     */
    public static List<UUID> orderPassengerIds(
            EventParticipantEntity driver,
            List<UUID> passengerIds,
            Map<UUID, EventParticipantEntity> byId,
            GeoPoint destination) {
        return orderPassengerIds(
                driver, passengerIds, byId, destination, DistanceCalculator::distanceMeters);
    }

    public static List<UUID> orderPassengerIds(
            EventParticipantEntity driver,
            List<UUID> passengerIds,
            Map<UUID, EventParticipantEntity> byId,
            GeoPoint destination,
            RouteDistanceMeter distanceMeter) {
        if (passengerIds.size() <= 1) {
            return List.copyOf(passengerIds);
        }

        if (GeoPoint.tripStartFromDriver(driver).isPresent()) {
            return nearestNeighborFromTripStart(passengerIds, byId, driver, distanceMeter);
        }

        return reverseNearestNeighborFromDestination(passengerIds, byId, destination, distanceMeter);
    }

    private static List<UUID> nearestNeighborFromTripStart(
            List<UUID> passengerIds,
            Map<UUID, EventParticipantEntity> byId,
            EventParticipantEntity driver,
            RouteDistanceMeter distanceMeter) {
        GeoPoint current = GeoPoint.tripStartFromDriver(driver).orElseThrow();
        Set<UUID> unvisited = new LinkedHashSet<>(passengerIds);
        List<UUID> order = new ArrayList<>(passengerIds.size());

        while (!unvisited.isEmpty()) {
            UUID nearest = pickNearest(unvisited, byId, current, distanceMeter);
            order.add(nearest);
            unvisited.remove(nearest);
            current = pickupPoint(byId.get(nearest));
        }

        return order;
    }

    private static List<UUID> reverseNearestNeighborFromDestination(
            List<UUID> passengerIds,
            Map<UUID, EventParticipantEntity> byId,
            GeoPoint destination,
            RouteDistanceMeter distanceMeter) {
        GeoPoint current = destination;
        Set<UUID> unvisited = new LinkedHashSet<>(passengerIds);
        List<UUID> order = new ArrayList<>(passengerIds.size());

        while (!unvisited.isEmpty()) {
            UUID nearest = pickNearest(unvisited, byId, current, distanceMeter);
            order.add(0, nearest);
            unvisited.remove(nearest);
            current = pickupPoint(byId.get(nearest));
        }

        return order;
    }

    private static UUID pickNearest(
            Set<UUID> candidates,
            Map<UUID, EventParticipantEntity> byId,
            GeoPoint from,
            RouteDistanceMeter distanceMeter) {
        UUID best = null;
        double bestDistance = Double.MAX_VALUE;

        for (UUID candidateId : candidates) {
            EventParticipantEntity passenger = byId.get(candidateId);
            GeoPoint pickup = pickupPoint(passenger);
            double distance = distanceMeter.distanceMeters(from, pickup);

            if (best == null
                    || distance < bestDistance
                    || (distance == bestDistance && passengerOrder().compare(passenger, byId.get(best)) < 0)) {
                best = candidateId;
                bestDistance = distance;
            }
        }

        return best;
    }

    private static GeoPoint pickupPoint(EventParticipantEntity passenger) {
        return GeoPoint.pickupFromPassenger(passenger).orElseThrow();
    }

    private static Comparator<EventParticipantEntity> passengerOrder() {
        return Comparator
                .comparing(EventParticipantEntity::getCreatedAt)
                .thenComparing(EventParticipantEntity::getId);
    }
}
