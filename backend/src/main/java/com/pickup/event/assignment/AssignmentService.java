package com.pickup.event.assignment;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.enums.StopStatus;
import com.pickup.common.enums.TripStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.common.geo.GeoLocationValidator;
import com.pickup.event.EventEntity;
import com.pickup.event.EventService;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.participant.ParticipantDisplayResolver;
import com.pickup.trip.TripEntity;
import com.pickup.trip.TripMapper;
import com.pickup.trip.TripRepository;
import com.pickup.trip.dto.TripResponse;
import com.pickup.trip.planning.TripRouteEnrichmentService;
import com.pickup.tripstop.TripStopEntity;
import com.pickup.vehicle.VehicleEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Organizer-driven manual passenger-to-driver assignment.
 *
 * <p>Phase 3A uses a single full-replace endpoint: the organizer submits the entire
 * plan and we atomically delete prior trips for the event and rebuild them. This
 * keeps trip and per-participant {@code ASSIGNED} status in lockstep without
 * incremental diffing.
 */
@Service
public class AssignmentService {

    /** Statuses considered "ready to participate" — eligible for inclusion in an assignment. */
    private static final Set<ParticipantStatus> ASSIGNABLE_STATES =
            EnumSet.of(ParticipantStatus.CONFIRMED, ParticipantStatus.READY, ParticipantStatus.ASSIGNED);

    private final EventService eventService;
    private final EventParticipantRepository participantRepository;
    private final TripRepository tripRepository;
    private final TripMapper tripMapper;
    private final TripRouteEnrichmentService tripRouteEnrichmentService;

    public AssignmentService(EventService eventService,
                             EventParticipantRepository participantRepository,
                             TripRepository tripRepository,
                             TripMapper tripMapper,
                             TripRouteEnrichmentService tripRouteEnrichmentService) {
        this.eventService = eventService;
        this.participantRepository = participantRepository;
        this.tripRepository = tripRepository;
        this.tripMapper = tripMapper;
        this.tripRouteEnrichmentService = tripRouteEnrichmentService;
    }

    /**
     * Atomic full-replace of an event's assignment plan. Validates every reference,
     * deletes existing trips (cascade removes stops), resets prior assignees back to
     * CONFIRMED, then creates fresh trips and bumps placed participants to ASSIGNED.
     */
    @Transactional
    public AssignmentPlanResponse submit(UUID organizerId,
                                         UUID eventId,
                                         SubmitAssignmentsRequest request) {
        EventEntity event = eventService.loadOrThrow(eventId);
        eventService.requireOrganizer(event, organizerId);

        // Index every participant in this event for O(1) lookups + safe membership checks.
        List<EventParticipantEntity> allParticipants =
                participantRepository.findAllByEventIdOrderByCreatedAtAsc(eventId);
        Map<UUID, EventParticipantEntity> byId = new HashMap<>();
        for (EventParticipantEntity p : allParticipants) {
            byId.put(p.getId(), p);
        }

        List<TripEntity> existingTrips = tripRepository.findAllByEventId(eventId);
        Set<UUID> lockedDriverParticipantIds = AssignmentPreservation.lockedDriverParticipantIds(
                eventId, existingTrips, participantRepository);

        // Validate the submitted plan against the indexed participants.
        Set<UUID> seenPassengers = new HashSet<>();
        Set<UUID> seenDrivers = new HashSet<>();
        List<ValidatedAssignment> validated = new ArrayList<>(request.assignments().size());

        for (DriverAssignment da : request.assignments()) {
            if (lockedDriverParticipantIds.contains(da.driverParticipantId())) {
                // Executed / in-flight trips are read-only in the assignment UI.
                continue;
            }
            EventParticipantEntity driver = byId.get(da.driverParticipantId());
            if (driver == null) {
                throw NotFoundException.of("Driver participant", da.driverParticipantId());
            }
            if (driver.getRole() != ParticipantRole.DRIVER) {
                throw new ConflictException(
                        "Participant " + driver.getId() + " is not a DRIVER (role: " + driver.getRole() + ")");
            }
            if (!ASSIGNABLE_STATES.contains(driver.getStatus())) {
                throw new ConflictException(
                        "Driver " + driver.getId() + " is not ready for assignment (status: " + driver.getStatus() + ")");
            }
            if (driver.getVehicle() == null) {
                throw new ConflictException(
                        "Driver " + driver.getId() + " has no vehicle selected for this event");
            }
            if (!seenDrivers.add(driver.getId())) {
                throw new ConflictException(
                        "Driver " + driver.getId() + " appears in the assignment plan more than once");
            }

            int seats = driver.getVehicle().getSeats();
            // Driver occupies one seat; passengers must fit in the remainder.
            int maxPassengers = Math.max(0, seats - 1);
            if (da.passengerParticipantIds().size() > maxPassengers) {
                throw new ConflictException(
                        "Driver " + driver.getId() + " vehicle has " + seats
                                + " seats; cannot fit " + da.passengerParticipantIds().size()
                                + " passengers (max " + maxPassengers + ")");
            }

            List<EventParticipantEntity> passengers = new ArrayList<>(da.passengerParticipantIds().size());
            for (UUID passengerId : da.passengerParticipantIds()) {
                EventParticipantEntity passenger = byId.get(passengerId);
                if (passenger == null) {
                    throw NotFoundException.of("Passenger participant", passengerId);
                }
                if (passenger.getRole() != ParticipantRole.PASSENGER) {
                    throw new ConflictException(
                            "Participant " + passenger.getId() + " is not a PASSENGER (role: "
                                    + passenger.getRole() + ")");
                }
                if (!ASSIGNABLE_STATES.contains(passenger.getStatus())) {
                    throw new ConflictException(
                            "Passenger " + passenger.getId() + " is not ready for assignment (status: "
                                    + passenger.getStatus() + ")");
                }
                if (!GeoLocationValidator.isComplete(
                        passenger.getPickupAddress(),
                        passenger.getPickupLat(),
                        passenger.getPickupLng())) {
                    throw new ConflictException(
                            "Passenger " + passenger.getId() + " is missing pickup address / lat / lng");
                }
                if (!seenPassengers.add(passenger.getId())) {
                    throw new ConflictException(
                            "Passenger " + passenger.getId() + " appears in more than one driver's plan");
                }
                passengers.add(passenger);
            }
            validated.add(new ValidatedAssignment(driver, passengers));
        }

        // Delete replaceable trips only; preserve executed / in-flight plans for history.
        for (TripEntity prior : existingTrips) {
            if (AssignmentPreservation.isPreserved(prior)) {
                continue;
            }
            EventParticipantEntity priorDriver = prior.getDriverParticipant();
            if (priorDriver == null && prior.getDriver() != null) {
                priorDriver = participantRepository
                        .findByEventIdAndUserId(eventId, prior.getDriver().getId())
                        .orElse(null);
            }
            if (priorDriver != null && priorDriver.getStatus() == ParticipantStatus.ASSIGNED) {
                priorDriver.setStatus(ParticipantDisplayResolver.priorAssignableStatus(priorDriver));
            }
            for (TripStopEntity stop : prior.getStops()) {
                EventParticipantEntity passenger = stop.getParticipant();
                if (passenger != null && passenger.getStatus() == ParticipantStatus.ASSIGNED) {
                    passenger.setStatus(ParticipantDisplayResolver.priorAssignableStatus(passenger));
                }
            }
            tripRepository.delete(prior);
        }
        // Flush deletes before inserts so the (trip_id, sequence) unique index never collides.
        tripRepository.flush();

        // Build the new trips. Stops follow the organizer-submitted order (sequence = index).
        List<TripEntity> created = new ArrayList<>(validated.size());
        for (ValidatedAssignment va : validated) {
            VehicleEntity vehicle = va.driver().getVehicle();
            TripEntity trip = TripEntity.builder()
                    .event(event)
                    .driver(va.driver().getUser())
                    .driverParticipant(va.driver())
                    .vehicle(vehicle)
                    .status(TripStatus.ASSIGNED)
                    .currentStop(null)
                    .finalDestinationAddress(event.getDestinationAddress())
                    .finalDestinationLat(event.getDestinationLat())
                    .finalDestinationLng(event.getDestinationLng())
                    .stops(new ArrayList<>())
                    .build();

            int seq = 0;
            for (EventParticipantEntity passenger : va.passengers()) {
                TripStopEntity stop = TripStopEntity.builder()
                        .trip(trip)
                        .participant(passenger)
                        .sequence(seq++)
                        .address(passenger.getPickupAddress())
                        .lat(passenger.getPickupLat())
                        .lng(passenger.getPickupLng())
                        .status(StopStatus.PENDING)
                        .meetingPointName(null)
                        .build();
                trip.getStops().add(stop);
                passenger.setStatus(ParticipantStatus.ASSIGNED);
            }
            va.driver().setStatus(ParticipantStatus.ASSIGNED);

            tripRouteEnrichmentService.enrichTrip(trip, event);
            created.add(tripRepository.save(trip));
        }

        List<TripEntity> preserved = existingTrips.stream()
                .filter(AssignmentPreservation::isPreserved)
                .toList();
        List<TripEntity> allTrips = new ArrayList<>(preserved.size() + created.size());
        allTrips.addAll(preserved);
        allTrips.addAll(created);
        return buildPlanResponse(eventId, allTrips, allParticipants);
    }

    /**
     * Read-only view of the current plan: all trips + the list of confirmed
     * passenger IDs not yet placed on any trip. Authorization: organizer or any
     * confirmed/assigned participant of the event.
     */
    @Transactional(readOnly = true)
    public AssignmentPlanResponse getPlan(UUID eventId, UUID viewerId) {
        EventEntity event = eventService.loadOrThrow(eventId);
        boolean isOrganizer = event.getOrganizer().getId().equals(viewerId);
        if (!isOrganizer) {
            boolean isParticipant = participantRepository
                    .findByEventIdAndUserId(eventId, viewerId)
                    .filter(p -> ASSIGNABLE_STATES.contains(p.getStatus())
                            || p.getRole() == ParticipantRole.ORGANIZER)
                    .isPresent();
            if (!isParticipant) {
                throw new ForbiddenException(
                        "You must be the organizer or a confirmed participant to view trips");
            }
        }
        List<TripEntity> trips = tripRepository.findAllByEventIdOrderByCreatedAtAsc(eventId);
        List<EventParticipantEntity> participants =
                participantRepository.findAllByEventIdOrderByCreatedAtAsc(eventId);
        return buildPlanResponse(eventId, trips, participants);
    }

    private AssignmentPlanResponse buildPlanResponse(UUID eventId,
                                                     List<TripEntity> trips,
                                                     List<EventParticipantEntity> allParticipants) {
        Set<UUID> assignedPassengerIds = new HashSet<>();
        for (TripEntity t : trips) {
            for (TripStopEntity s : t.getStops()) {
                assignedPassengerIds.add(s.getParticipant().getId());
            }
        }
        List<UUID> unassigned = allParticipants.stream()
                .filter(p -> p.getRole() == ParticipantRole.PASSENGER)
                .filter(p -> ASSIGNABLE_STATES.contains(p.getStatus()))
                .map(EventParticipantEntity::getId)
                .filter(id -> !assignedPassengerIds.contains(id))
                .toList();
        List<TripResponse> tripDtos = trips.stream().map(tripMapper::toResponse).toList();
        return new AssignmentPlanResponse(eventId, tripDtos, unassigned);
    }

    private record ValidatedAssignment(EventParticipantEntity driver,
                                       List<EventParticipantEntity> passengers) {}
}
