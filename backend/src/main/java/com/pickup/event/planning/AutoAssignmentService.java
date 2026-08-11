package com.pickup.event.planning;

import com.pickup.common.enums.EventPlanningStatus;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.geo.GeoLocationValidator;
import com.pickup.common.geo.GeoPoint;
import com.pickup.common.geo.routing.RouteEstimateService;
import com.pickup.event.EventEntity;
import com.pickup.event.EventRepository;
import com.pickup.event.EventService;
import com.pickup.event.assignment.AssignmentPreservation;
import com.pickup.event.assignment.AssignmentService;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripEntity;
import com.pickup.trip.TripRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Deterministic auto-assignment: builds a full-replace plan and delegates
 * persistence to {@link AssignmentService#submit}. Only replaceable trips are
 * rebuilt; preserved in-flight trips and their drivers/passengers are excluded.
 *
 * <p>Phase 4B adds proximity-based driver–passenger matching and nearest-neighbor
 * stop ordering before submit. For {@code DRIVER} participants, {@code pickupLat/Lng}
 * is the trip start location used by those heuristics.
 */
@Service
public class AutoAssignmentService {

    /** Same assignable pool as manual assignment. */
    private static final Set<ParticipantStatus> ASSIGNABLE_STATES =
            EnumSet.of(ParticipantStatus.CONFIRMED, ParticipantStatus.READY, ParticipantStatus.ASSIGNED);

    private final EventService eventService;
    private final EventRepository eventRepository;
    private final EventParticipantRepository participantRepository;
    private final TripRepository tripRepository;
    private final AssignmentService assignmentService;
    private final EventPlanningStatusWriter planningStatusWriter;
    private final RouteEstimateService routeEstimateService;

    public AutoAssignmentService(EventService eventService,
                                 EventRepository eventRepository,
                                 EventParticipantRepository participantRepository,
                                 TripRepository tripRepository,
                                 AssignmentService assignmentService,
                                 EventPlanningStatusWriter planningStatusWriter,
                                 RouteEstimateService routeEstimateService) {
        this.eventService = eventService;
        this.eventRepository = eventRepository;
        this.participantRepository = participantRepository;
        this.tripRepository = tripRepository;
        this.assignmentService = assignmentService;
        this.planningStatusWriter = planningStatusWriter;
        this.routeEstimateService = routeEstimateService;
    }

    @Transactional
    public AssignmentPlanResponse generate(UUID organizerId, UUID eventId) {
        EventEntity event = eventService.loadOrThrow(eventId);
        eventService.requireOrganizer(event, organizerId);

        event.setPlanningStatus(EventPlanningStatus.IN_PROGRESS);
        eventRepository.save(event);

        try {
            List<EventParticipantEntity> allParticipants =
                    participantRepository.findAllByEventIdOrderByCreatedAtAsc(eventId);
            List<TripEntity> existingTrips = tripRepository.findAllByEventId(eventId);

            Set<UUID> lockedDriverIds = AssignmentPreservation.lockedDriverParticipantIds(
                    eventId, existingTrips, participantRepository);
            Set<UUID> lockedPassengerIds =
                    AssignmentPreservation.lockedPassengerParticipantIds(existingTrips);

            List<EventParticipantEntity> eligibleDrivers = allParticipants.stream()
                    .filter(p -> p.getRole() == ParticipantRole.DRIVER)
                    .filter(p -> ASSIGNABLE_STATES.contains(p.getStatus()))
                    .filter(p -> p.getVehicle() != null)
                    .filter(p -> !lockedDriverIds.contains(p.getId()))
                    .sorted(participantOrder())
                    .toList();

            List<EventParticipantEntity> eligiblePassengers = allParticipants.stream()
                    .filter(p -> p.getRole() == ParticipantRole.PASSENGER)
                    .filter(p -> ASSIGNABLE_STATES.contains(p.getStatus()))
                    .filter(this::hasCompletePickup)
                    .filter(p -> !lockedPassengerIds.contains(p.getId()))
                    .sorted(participantOrder())
                    .toList();

            Map<UUID, EventParticipantEntity> byId = new HashMap<>();
            for (EventParticipantEntity participant : allParticipants) {
                byId.put(participant.getId(), participant);
            }

            GeoPoint destination = new GeoPoint(event.getDestinationLat(), event.getDestinationLng());

            List<DriverAssignment> assignments =
                    DriverPassengerScorer.assign(
                            eligibleDrivers,
                            eligiblePassengers,
                            destination,
                            routeEstimateService::distanceMeters);

            List<DriverAssignment> orderedAssignments = new ArrayList<>(assignments.size());
            for (DriverAssignment assignment : assignments) {
                EventParticipantEntity driver = byId.get(assignment.driverParticipantId());
                List<UUID> orderedPassengerIds = StopOrderPlanner.orderPassengerIds(
                        driver,
                        assignment.passengerParticipantIds(),
                        byId,
                        destination,
                        routeEstimateService::distanceMeters);
                orderedAssignments.add(new DriverAssignment(
                        assignment.driverParticipantId(),
                        orderedPassengerIds));
            }

            SubmitAssignmentsRequest request = new SubmitAssignmentsRequest(orderedAssignments);
            AssignmentPlanResponse response =
                    assignmentService.submit(organizerId, eventId, request);

            event.setPlanningStatus(EventPlanningStatus.READY);
            event.setAssignmentGenerated(true);
            eventRepository.save(event);

            return response;
        } catch (RuntimeException e) {
            planningStatusWriter.markFailed(eventId);
            throw e;
        }
    }

    private static Comparator<EventParticipantEntity> participantOrder() {
        return Comparator
                .comparing(EventParticipantEntity::getCreatedAt)
                .thenComparing(EventParticipantEntity::getId);
    }

    private boolean hasCompletePickup(EventParticipantEntity passenger) {
        return GeoLocationValidator.isComplete(
                passenger.getPickupAddress(),
                passenger.getPickupLat(),
                passenger.getPickupLng());
    }
}
