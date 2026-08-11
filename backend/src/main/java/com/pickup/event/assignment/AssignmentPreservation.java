package com.pickup.event.assignment;

import com.pickup.common.enums.TripStatus;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripEntity;
import com.pickup.tripstop.TripStopEntity;

import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Shared rules for trips that have left the planning phase and must not be
 * rebuilt by manual or automatic assignment.
 */
public final class AssignmentPreservation {

    /**
     * Trips that have left the planning phase are preserved on re-submit so organizers
     * can still see historical assignments and in-flight execution is not wiped.
     */
    public static final Set<TripStatus> PRESERVED_TRIP_STATUSES = EnumSet.of(
            TripStatus.STARTED,
            TripStatus.IN_PROGRESS,
            TripStatus.WAITING_FOR_NEXT_STOP,
            TripStatus.ALL_PASSENGERS_PICKED,
            TripStatus.HEADING_TO_DESTINATION,
            TripStatus.COMPLETED,
            TripStatus.INTERRUPTED
    );

    private AssignmentPreservation() {}

    public static boolean isPreserved(TripEntity trip) {
        return PRESERVED_TRIP_STATUSES.contains(trip.getStatus());
    }

    /**
     * Driver participant IDs tied to preserved (in-flight or completed) trips.
     * These drivers must be excluded from auto-assignment and skipped on manual re-submit.
     *
     * <p>Trips created since Phase 4D-2 carry {@link TripEntity#getDriverParticipant()}
     * directly; legacy trips created before then fall back to a (event, user) lookup.
     */
    public static Set<UUID> lockedDriverParticipantIds(UUID eventId,
                                                       List<TripEntity> trips,
                                                       EventParticipantRepository participantRepository) {
        Set<UUID> locked = new HashSet<>();
        for (TripEntity trip : trips) {
            if (!isPreserved(trip)) {
                continue;
            }
            EventParticipantEntity driverParticipant = trip.getDriverParticipant();
            if (driverParticipant != null) {
                locked.add(driverParticipant.getId());
            } else if (trip.getDriver() != null) {
                participantRepository.findByEventIdAndUserId(eventId, trip.getDriver().getId())
                        .ifPresent(p -> locked.add(p.getId()));
            }
        }
        return locked;
    }

    /**
     * Passenger participant IDs already on stops belonging to preserved trips.
     * These passengers must not be reassigned while their in-flight ride stands.
     */
    public static Set<UUID> lockedPassengerParticipantIds(List<TripEntity> trips) {
        Set<UUID> locked = new HashSet<>();
        for (TripEntity trip : trips) {
            if (!isPreserved(trip)) {
                continue;
            }
            for (TripStopEntity stop : trip.getStops()) {
                EventParticipantEntity passenger = stop.getParticipant();
                if (passenger != null && passenger.getId() != null) {
                    locked.add(passenger.getId());
                }
            }
        }
        return locked;
    }
}
