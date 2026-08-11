package com.pickup.trip;

import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.enums.StopStatus;
import com.pickup.common.enums.TripStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.dto.TripResponse;
import com.pickup.trip.dto.UpdateTripStopRequest;
import com.pickup.tripstop.TripStopEntity;
import com.pickup.tripstop.TripStopRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Driver-facing trip execution lifecycle for Phase 3B.
 *
 * <p>Owns mutation of {@link TripEntity#status}, {@link TripEntity#currentStop},
 * {@code startedAt} / {@code completedAt}, the per-stop transitions out of
 * {@link StopStatus#ACTIVE}, and the participant-status side effects driven by
 * pickup / no-show / cancellation / arrival events. Reads stay in {@link TripService}.
 *
 * <p>Status model used in this phase:
 * {@code ASSIGNED -> IN_PROGRESS -> ALL_PASSENGERS_PICKED -> COMPLETED}.
 * {@code STARTED}, {@code HEADING_TO_DESTINATION}, and {@code INTERRUPTED} are
 * intentionally unused. External navigation targets are computed at read time (Phase 3C); driver abort remains a later phase.
 */
@Service
public class TripExecutionService {

    private final TripService tripService;
    private final TripRepository tripRepository;
    private final TripStopRepository tripStopRepository;
    private final EventParticipantRepository participantRepository;
    private final TripMapper tripMapper;

    public TripExecutionService(TripService tripService,
                                TripRepository tripRepository,
                                TripStopRepository tripStopRepository,
                                EventParticipantRepository participantRepository,
                                TripMapper tripMapper) {
        this.tripService = tripService;
        this.tripRepository = tripRepository;
        this.tripStopRepository = tripStopRepository;
        this.participantRepository = participantRepository;
        this.tripMapper = tripMapper;
    }

    /**
     * Driver kicks off the trip. Transitions {@code ASSIGNED -> IN_PROGRESS},
     * stamps {@code startedAt}, activates the first stop in sequence order, and
     * points {@code currentStop} at it.
     */
    @Transactional
    public TripResponse start(UUID tripId, UUID callerId) {
        TripEntity trip = tripService.loadOrThrow(tripId);
        requireDriver(trip, callerId);

        if (trip.getStatus() != TripStatus.ASSIGNED) {
            throw new ConflictException(
                    "Trip can only be started from ASSIGNED (current: " + trip.getStatus() + ")");
        }
        // Use the repository helper rather than trip.getStops() so we never depend on lazy-load order.
        TripStopEntity firstStop = tripStopRepository
                .findFirstByTripIdAndStatusOrderBySequenceAsc(trip.getId(), StopStatus.PENDING)
                .orElseThrow(() -> new ConflictException(
                        "Trip has no stops to pick up; cannot start"));

        trip.setStatus(TripStatus.IN_PROGRESS);
        trip.setStartedAt(Instant.now());
        firstStop.setStatus(StopStatus.ACTIVE);
        trip.setCurrentStop(firstStop);

        return tripMapper.toResponse(trip);
    }

    /**
     * Driver resolves the trip's single currently-active stop. Applies the requested
     * transition, stamps best-effort timestamps, propagates the participant status
     * side effect, and advances {@code currentStop} to the next PENDING stop — or
     * promotes the trip to {@link TripStatus#ALL_PASSENGERS_PICKED} when none remain.
     */
    @Transactional
    public TripResponse updateStop(UUID tripId,
                                   UUID stopId,
                                   UUID callerId,
                                   UpdateTripStopRequest request) {
        TripEntity trip = tripService.loadOrThrow(tripId);
        requireDriver(trip, callerId);

        if (trip.getStatus() != TripStatus.IN_PROGRESS) {
            throw new ConflictException(
                    "Stops can only be updated while the trip is IN_PROGRESS (current: "
                            + trip.getStatus() + ")");
        }

        TripStopEntity stop = tripStopRepository.findById(stopId)
                .orElseThrow(() -> NotFoundException.of("Trip stop", stopId));
        if (!stop.getTrip().getId().equals(trip.getId())) {
            // Treat as not found from the caller's perspective rather than leaking cross-trip info.
            throw NotFoundException.of("Trip stop", stopId);
        }
        TripStopEntity current = trip.getCurrentStop();
        if (current == null || !current.getId().equals(stop.getId())) {
            throw new ConflictException(
                    "Only the current active stop may be updated");
        }
        if (stop.getStatus() != StopStatus.ACTIVE) {
            // Defensive: currentStop and stop.status are kept in sync by this service, but
            // if anything ever drifts we refuse rather than corrupt the timeline further.
            throw new ConflictException(
                    "Current stop is not ACTIVE (status: " + stop.getStatus() + ")");
        }

        Instant now = Instant.now();
        StopStatus resolved = switch (request.action()) {
            case PICK_UP -> StopStatus.PICKED_UP;
            case SKIP    -> StopStatus.SKIPPED;
            case CANCEL  -> StopStatus.CANCELLED;
        };
        stop.setStatus(resolved);
        applyResolutionTimestamps(stop, resolved, now);
        applyParticipantSideEffect(stop.getParticipant(), resolved);

        // Activate the next PENDING stop, or promote the trip to "all passengers picked".
        Optional<TripStopEntity> next = tripStopRepository
                .findFirstByTripIdAndStatusOrderBySequenceAsc(trip.getId(), StopStatus.PENDING);
        if (next.isPresent()) {
            TripStopEntity nextStop = next.get();
            nextStop.setStatus(StopStatus.ACTIVE);
            trip.setCurrentStop(nextStop);
        } else {
            trip.setCurrentStop(null);
            trip.setStatus(TripStatus.ALL_PASSENGERS_PICKED);
        }

        return tripMapper.toResponse(trip);
    }

    /**
     * Driver finalizes the trip. Only allowed from {@link TripStatus#ALL_PASSENGERS_PICKED};
     * defensively normalizes a stranded {@code IN_PROGRESS} trip with no remaining
     * PENDING/ACTIVE stops first. Drives picked-up passengers (and the driver) to
     * {@link ParticipantStatus#ARRIVED}.
     */
    @Transactional
    public TripResponse complete(UUID tripId, UUID callerId) {
        TripEntity trip = tripService.loadOrThrow(tripId);
        requireDriver(trip, callerId);

        if (trip.getStatus() == TripStatus.IN_PROGRESS) {
            boolean stillActive = tripStopRepository
                    .findFirstByTripIdAndStatusOrderBySequenceAsc(trip.getId(), StopStatus.ACTIVE)
                    .isPresent();
            boolean stillPending = tripStopRepository
                    .findFirstByTripIdAndStatusOrderBySequenceAsc(trip.getId(), StopStatus.PENDING)
                    .isPresent();
            if (!stillActive && !stillPending) {
                trip.setStatus(TripStatus.ALL_PASSENGERS_PICKED);
                trip.setCurrentStop(null);
            }
        }
        if (trip.getStatus() != TripStatus.ALL_PASSENGERS_PICKED) {
            throw new ConflictException(
                    "Trip can only be completed once all stops are resolved (current: "
                            + trip.getStatus() + ")");
        }

        trip.setStatus(TripStatus.COMPLETED);
        trip.setCompletedAt(Instant.now());
        trip.setCurrentStop(null);

        // Picked-up passengers reach the destination with the trip; everyone else
        // stays at the status set when their stop was resolved (NO_SHOW / CANCELLED).
        for (TripStopEntity stop : trip.getStops()) {
            if (stop.getStatus() == StopStatus.PICKED_UP) {
                EventParticipantEntity passenger = stop.getParticipant();
                if (passenger != null && passenger.getStatus() == ParticipantStatus.PICKED_UP) {
                    passenger.setStatus(ParticipantStatus.ARRIVED);
                }
            }
        }
        // Driver participant arrives alongside the trip. Look them up by (event, user)
        // since a Trip references the User, not the EventParticipant.
        participantRepository
                .findByEventIdAndUserId(trip.getEvent().getId(), trip.getDriver().getId())
                .filter(p -> p.getStatus() == ParticipantStatus.ASSIGNED)
                .ifPresent(p -> p.setStatus(ParticipantStatus.ARRIVED));

        return tripMapper.toResponse(trip);
    }

    private void requireDriver(TripEntity trip, UUID callerId) {
        // Contact-backed drivers have no registered user (Phase 4D-3 defers their
        // execution auth), so trips without a user driver simply reject all callers here.
        if (trip.getDriver() == null || !trip.getDriver().getId().equals(callerId)) {
            throw new ForbiddenException("Only the trip driver may perform this action");
        }
    }

    /**
     * Best-effort arrival/departure timestamps in the absence of map navigation.
     * Phase 3C will tighten this once an explicit {@code ARRIVED} action exists.
     */
    private void applyResolutionTimestamps(TripStopEntity stop, StopStatus resolved, Instant now) {
        switch (resolved) {
            case PICKED_UP, SKIPPED -> {
                stop.setActualArrivalTime(now);
                stop.setActualDepartureTime(now);
            }
            case CANCELLED -> stop.setActualArrivalTime(now);
            default -> {
                // no-op: other StopStatus values are not produced by this service in Phase 3B.
            }
        }
    }

    /**
     * Mirror the stop transition onto the passenger participant so per-event status
     * tracking stays coherent (used by dashboards and downstream notifications later).
     */
    private void applyParticipantSideEffect(EventParticipantEntity passenger, StopStatus resolved) {
        if (passenger == null || passenger.getStatus() != ParticipantStatus.ASSIGNED) {
            return;
        }
        switch (resolved) {
            case PICKED_UP -> passenger.setStatus(ParticipantStatus.PICKED_UP);
            case SKIPPED   -> passenger.setStatus(ParticipantStatus.NO_SHOW);
            case CANCELLED -> passenger.setStatus(ParticipantStatus.CANCELLED);
            default -> {
                // no-op
            }
        }
    }
}
