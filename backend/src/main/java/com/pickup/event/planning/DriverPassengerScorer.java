package com.pickup.event.planning;

import com.pickup.common.geo.DistanceCalculator;
import com.pickup.common.geo.GeoPoint;
import com.pickup.common.geo.routing.RouteDistanceMeter;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.vehicle.VehicleEntity;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Greedy driver–passenger matching by geographic proximity and deterministic tie-breakers.
 *
 * <p>For {@code DRIVER} participants, {@code pickupLat/Lng} is interpreted as the driver's
 * trip start location (where the route begins before the first passenger stop).
 */
public final class DriverPassengerScorer {

    private DriverPassengerScorer() {}

    /**
     * Assign each passenger to the best-scoring eligible driver with remaining capacity.
     * Passengers and drivers must already be sorted deterministically by caller.
     */
    public static List<DriverAssignment> assign(
            List<EventParticipantEntity> drivers,
            List<EventParticipantEntity> passengers,
            GeoPoint destination) {
        return assign(drivers, passengers, destination, DistanceCalculator::distanceMeters);
    }

    public static List<DriverAssignment> assign(
            List<EventParticipantEntity> drivers,
            List<EventParticipantEntity> passengers,
            GeoPoint destination,
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

        for (EventParticipantEntity passenger : passengers) {
            GeoPoint passengerPickup = GeoPoint.pickupFromPassenger(passenger).orElseThrow();

            EventParticipantEntity bestDriver = null;
            for (EventParticipantEntity driver : drivers) {
                int capacity = remainingCapacity.getOrDefault(driver.getId(), 0);
                if (capacity <= 0) {
                    continue;
                }
                if (bestDriver == null
                        || compareDrivers(
                                driver,
                                bestDriver,
                                passengerPickup,
                                destination,
                                remainingCapacity,
                                distanceMeter)
                                < 0) {
                    bestDriver = driver;
                }
            }

            if (bestDriver == null) {
                continue;
            }

            UUID driverId = bestDriver.getId();
            assignedByDriver.get(driverId).add(passenger.getId());
            remainingCapacity.merge(driverId, 1, (left, dec) -> left - dec);
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

    private static int compareDrivers(
            EventParticipantEntity candidate,
            EventParticipantEntity incumbent,
            GeoPoint passengerPickup,
            GeoPoint destination,
            Map<UUID, Integer> remainingCapacity,
            RouteDistanceMeter distanceMeter) {
        int proximity = Double.compare(
                proximityMeters(candidate, passengerPickup, distanceMeter),
                proximityMeters(incumbent, passengerPickup, distanceMeter));
        if (proximity != 0) {
            return proximity;
        }

        int capacity = Integer.compare(
                -remainingCapacity.getOrDefault(candidate.getId(), 0),
                -remainingCapacity.getOrDefault(incumbent.getId(), 0));
        if (capacity != 0) {
            return capacity;
        }

        int alignment = Double.compare(
                destinationAlignmentMeters(candidate, passengerPickup, destination, distanceMeter),
                destinationAlignmentMeters(incumbent, passengerPickup, destination, distanceMeter));
        if (alignment != 0) {
            return alignment;
        }

        return participantOrder().compare(candidate, incumbent);
    }

    private static double proximityMeters(
            EventParticipantEntity driver,
            GeoPoint passengerPickup,
            RouteDistanceMeter distanceMeter) {
        return GeoPoint.tripStartFromDriver(driver)
                .map(start -> distanceMeter.distanceMeters(start, passengerPickup))
                .orElse(Double.MAX_VALUE);
    }

    private static double destinationAlignmentMeters(
            EventParticipantEntity driver,
            GeoPoint passengerPickup,
            GeoPoint destination,
            RouteDistanceMeter distanceMeter) {
        double driverToDest = GeoPoint.tripStartFromDriver(driver)
                .map(start -> distanceMeter.distanceMeters(start, destination))
                .orElse(Double.MAX_VALUE);
        double passengerToDest = distanceMeter.distanceMeters(passengerPickup, destination);
        return Math.abs(driverToDest - passengerToDest);
    }

    private static Comparator<EventParticipantEntity> participantOrder() {
        return Comparator
                .comparing(EventParticipantEntity::getCreatedAt)
                .thenComparing(EventParticipantEntity::getId);
    }
}
