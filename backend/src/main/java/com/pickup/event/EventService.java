package com.pickup.event;

import com.pickup.common.enums.EventStatus;
import com.pickup.common.geo.GeoLocationValidator;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.event.dto.CreateEventRequest;
import com.pickup.event.dto.EventDashboardResponse;
import com.pickup.event.dto.EventDashboardSummary;
import com.pickup.event.dto.EventResponse;
import com.pickup.event.dto.OrganizerDashboardResponse;
import com.pickup.event.dto.UpdateEventRequest;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class EventService {

    private static final Set<EventStatus> EDITABLE_STATES =
            Set.of(EventStatus.DRAFT, EventStatus.OPEN, EventStatus.CLOSED);
    private static final Set<EventStatus> DELETABLE_STATES =
            Set.of(EventStatus.DRAFT, EventStatus.CANCELLED);
    private static final Set<EventStatus> ACTIVE_EVENT_STATES =
            EnumSet.of(EventStatus.DRAFT, EventStatus.OPEN, EventStatus.CLOSED, EventStatus.IN_PROGRESS);
    private static final Set<ParticipantStatus> ACTIVE_PARTICIPANT_STATES =
            EnumSet.of(ParticipantStatus.APPROVED, ParticipantStatus.CONFIRMED, ParticipantStatus.READY);
    /** Passengers still waiting for or actively on a ride (excludes arrived / checked-in). */
    private static final Set<ParticipantStatus> PASSENGER_NEEDS_RIDE_STATES =
            EnumSet.of(
                    ParticipantStatus.APPROVED,
                    ParticipantStatus.CONFIRMED,
                    ParticipantStatus.READY,
                    ParticipantStatus.ASSIGNED,
                    ParticipantStatus.PICKED_UP);
    /**
     * Statuses that should NOT be counted toward "participants actually coming".
     * Excludes drop-outs (cancelled/rejected/no-show) and unaccepted states
     * (invited/requested) so the headline "X participants" number reflects
     * accepted attendees only and matches across dashboard + event detail.
     */
    private static final Set<ParticipantStatus> NON_ATTENDING_PARTICIPANT_STATUSES =
            EnumSet.of(
                    ParticipantStatus.INVITED,
                    ParticipantStatus.REQUESTED,
                    ParticipantStatus.REJECTED,
                    ParticipantStatus.CANCELLED,
                    ParticipantStatus.NO_SHOW);

    private final EventRepository eventRepository;
    private final EventParticipantRepository participantRepository;
    private final UserRepository userRepository;
    private final EventMapper eventMapper;

    public EventService(EventRepository eventRepository,
                        EventParticipantRepository participantRepository,
                        UserRepository userRepository,
                        EventMapper eventMapper) {
        this.eventRepository = eventRepository;
        this.participantRepository = participantRepository;
        this.userRepository = userRepository;
        this.eventMapper = eventMapper;
    }

    @Transactional
    public EventResponse createEvent(UUID organizerId, CreateEventRequest request) {
        UserEntity organizer = userRepository.findById(organizerId)
                .orElseThrow(() -> NotFoundException.of("User", organizerId));

        GeoLocationValidator.requireComplete(
                request.destinationAddress(),
                request.destinationLat(),
                request.destinationLng(),
                "Destination");

        EventEntity event = EventEntity.builder()
                .organizer(organizer)
                .title(request.title().trim())
                .description(request.description())
                .destinationAddress(request.destinationAddress().trim())
                .destinationLat(request.destinationLat())
                .destinationLng(request.destinationLng())
                .eventTime(request.eventTime())
                .status(EventStatus.OPEN)
                .build();
        event = eventRepository.save(event);

        EventParticipantEntity organizerParticipant = EventParticipantEntity.builder()
                .event(event)
                .user(organizer)
                .role(ParticipantRole.ORGANIZER)
                .status(ParticipantStatus.CONFIRMED)
                .build();
        participantRepository.save(organizerParticipant);

        return eventMapper.toResponse(event, 1);
    }

    @Transactional(readOnly = true)
    public List<EventResponse> listMyEvents(UUID organizerId) {
        List<EventEntity> events = eventRepository.findAllByOrganizerIdOrderByEventTimeAsc(organizerId);
        return mapWithCounts(events);
    }

    @Transactional(readOnly = true)
    public List<EventResponse> listJoinedEvents(UUID userId) {
        // participantRepository.findAllByUserId fetches participant rows;
        // p.getEvent() needs an active session — @Transactional provides it.
        List<EventParticipantEntity> myRows = participantRepository.findAllByUserId(userId).stream()
                .filter(p -> p.getRole() != ParticipantRole.ORGANIZER)
                .toList();
        // One row per event (a user has at most one participant row per event today).
        Map<UUID, EventParticipantEntity> byEventId = new HashMap<>();
        for (EventParticipantEntity p : myRows) {
            byEventId.putIfAbsent(p.getEvent().getId(), p);
        }
        List<EventEntity> events = myRows.stream()
                .map(EventParticipantEntity::getEvent)
                .distinct()
                .sorted(java.util.Comparator.comparing(EventEntity::getEventTime))
                .toList();
        return mapWithCounts(events, byEventId);
    }

    @Transactional(readOnly = true)
    public List<EventResponse> listOpenEvents(UUID currentUserId) {
        List<EventEntity> openEvents = eventRepository.findAllByStatusOrderByEventTimeAsc(EventStatus.OPEN);
        // exclude events I'm already a participant of
        List<EventEntity> filtered = openEvents.stream()
                .filter(e -> !participantRepository.existsByEventIdAndUserId(e.getId(), currentUserId))
                .toList();
        return mapWithCounts(filtered);
    }

    @Transactional(readOnly = true)
    public EventResponse getEvent(UUID eventId, UUID viewerId) {
        EventEntity event = loadOrThrow(eventId);
        long count = participantRepository.countActiveByEventId(eventId, NON_ATTENDING_PARTICIPANT_STATUSES);
        ParticipantRole viewerRole = null;
        ParticipantStatus viewerStatus = null;
        if (viewerId != null) {
            var viewerRow = participantRepository.findByEventIdAndUserId(eventId, viewerId);
            if (viewerRow.isPresent()) {
                viewerRole = viewerRow.get().getRole();
                viewerStatus = viewerRow.get().getStatus();
            }
        }
        return eventMapper.toResponse(event, (int) count, viewerRole, viewerStatus);
    }

    @Transactional
    public EventResponse updateEvent(UUID organizerId, UUID eventId, UpdateEventRequest request) {
        EventEntity event = loadOrThrow(eventId);
        requireOrganizer(event, organizerId);
        if (!EDITABLE_STATES.contains(event.getStatus())) {
            throw new ConflictException("Event cannot be edited in status " + event.getStatus());
        }
        if (request.title() != null && !request.title().isBlank()) {
            event.setTitle(request.title().trim());
        }
        if (request.description() != null) {
            event.setDescription(request.description());
        }
        boolean destinationTouched = request.destinationAddress() != null
                || request.destinationLat() != null
                || request.destinationLng() != null;
        if (request.destinationAddress() != null && !request.destinationAddress().isBlank()) {
            event.setDestinationAddress(request.destinationAddress().trim());
        }
        if (request.destinationLat() != null) {
            event.setDestinationLat(request.destinationLat());
        }
        if (request.destinationLng() != null) {
            event.setDestinationLng(request.destinationLng());
        }
        if (destinationTouched) {
            GeoLocationValidator.requireComplete(
                    event.getDestinationAddress(),
                    event.getDestinationLat(),
                    event.getDestinationLng(),
                    "Destination");
        }
        if (request.eventTime() != null) {
            event.setEventTime(request.eventTime());
        }
        long count = participantRepository.countActiveByEventId(eventId, NON_ATTENDING_PARTICIPANT_STATUSES);
        return eventMapper.toResponse(event, (int) count);
    }

    @Transactional
    public EventResponse closeEvent(UUID organizerId, UUID eventId) {
        EventEntity event = loadOrThrow(eventId);
        requireOrganizer(event, organizerId);
        if (event.getStatus() != EventStatus.OPEN) {
            throw new ConflictException("Only OPEN events can be closed (current: " + event.getStatus() + ")");
        }
        event.setStatus(EventStatus.CLOSED);
        long count = participantRepository.countActiveByEventId(eventId, NON_ATTENDING_PARTICIPANT_STATUSES);
        return eventMapper.toResponse(event, (int) count);
    }

    @Transactional
    public EventResponse reopenEvent(UUID organizerId, UUID eventId) {
        EventEntity event = loadOrThrow(eventId);
        requireOrganizer(event, organizerId);
        if (event.getStatus() != EventStatus.CLOSED) {
            throw new ConflictException("Only CLOSED events can be reopened (current: " + event.getStatus() + ")");
        }
        event.setStatus(EventStatus.OPEN);
        long count = participantRepository.countActiveByEventId(eventId, NON_ATTENDING_PARTICIPANT_STATUSES);
        return eventMapper.toResponse(event, (int) count);
    }

    @Transactional
    public EventResponse cancelEvent(UUID organizerId, UUID eventId) {
        EventEntity event = loadOrThrow(eventId);
        requireOrganizer(event, organizerId);
        if (event.getStatus() == EventStatus.COMPLETED || event.getStatus() == EventStatus.CANCELLED) {
            throw new ConflictException("Event cannot be cancelled in status " + event.getStatus());
        }
        event.setStatus(EventStatus.CANCELLED);
        long count = participantRepository.countActiveByEventId(eventId, NON_ATTENDING_PARTICIPANT_STATUSES);
        return eventMapper.toResponse(event, (int) count);
    }

    @Transactional
    public void deleteEvent(UUID organizerId, UUID eventId) {
        EventEntity event = loadOrThrow(eventId);
        requireOrganizer(event, organizerId);
        if (!DELETABLE_STATES.contains(event.getStatus())) {
            throw new ConflictException("Event can only be deleted while DRAFT or CANCELLED");
        }
        // delete participants first to satisfy FK; safe because event isn't active.
        participantRepository.findAllByEventId(eventId).forEach(participantRepository::delete);
        eventRepository.delete(event);
    }

    public EventEntity loadOrThrow(UUID eventId) {
        return eventRepository.findById(eventId)
                .orElseThrow(() -> NotFoundException.of("Event", eventId));
    }

    public void requireOrganizer(EventEntity event, UUID userId) {
        if (!event.getOrganizer().getId().equals(userId)) {
            throw new ForbiddenException("Only the event organizer may perform this action");
        }
    }

    @Transactional(readOnly = true)
    public EventDashboardResponse getEventDashboard(UUID eventId) {
        EventEntity event = loadOrThrow(eventId);
        List<EventParticipantEntity> participants =
                participantRepository.findAllByEventIdOrderByCreatedAtAsc(eventId);

        int total = 0, organizers = 0, drivers = 0, passengers = 0, independents = 0, pending = 0;
        int totalSeats = 0, driversMissingVehicle = 0;
        for (EventParticipantEntity p : participants) {
            total++;
            boolean isActive = ACTIVE_PARTICIPANT_STATES.contains(p.getStatus());
            switch (p.getRole()) {
                case ORGANIZER -> {
                    if (isActive) organizers++;
                }
                case DRIVER -> {
                    if (isAttendingDriver(p)) {
                        drivers++;
                        if (p.getVehicle() == null) {
                            driversMissingVehicle++;
                        } else {
                            totalSeats += p.getVehicle().getSeats();
                        }
                    }
                }
                case PASSENGER -> {
                    if (PASSENGER_NEEDS_RIDE_STATES.contains(p.getStatus())) passengers++;
                }
                case INDEPENDENT_ATTENDEE -> {
                    if (isActive) independents++;
                }
            }
            if (p.getStatus() == ParticipantStatus.REQUESTED) {
                pending++;
            }
        }
        int seatsSurplus = totalSeats - passengers;

        return new EventDashboardResponse(
                event.getId(),
                event.getTitle(),
                event.getEventTime(),
                event.getStatus(),
                event.getPlanningStatus(),
                new EventDashboardResponse.Totals(
                        total, organizers, drivers, passengers, independents, pending),
                new EventDashboardResponse.Seats(
                        totalSeats, passengers, seatsSurplus, driversMissingVehicle)
        );
    }

    @Transactional(readOnly = true)
    public OrganizerDashboardResponse getOrganizerDashboard(UUID organizerId) {
        List<EventEntity> events = eventRepository.findAllByOrganizerIdOrderByEventTimeAsc(organizerId);
        List<EventDashboardSummary> summaries = events.stream()
                .map(e -> summarize(e, participantRepository.findAllByEventIdOrderByCreatedAtAsc(e.getId())))
                .toList();
        int active = (int) events.stream().filter(e -> ACTIVE_EVENT_STATES.contains(e.getStatus())).count();
        return new OrganizerDashboardResponse(events.size(), active, summaries);
    }

    private EventDashboardSummary summarize(EventEntity event, List<EventParticipantEntity> participants) {
        // "Total participants" means accepted attendees actually coming —
        // not pending requests, rejections, cancellations, or no-shows.
        // This matches the count shown on the event detail page.
        int total = 0, confirmedDrivers = 0, passengers = 0, pending = 0;
        for (EventParticipantEntity p : participants) {
            boolean attending = !NON_ATTENDING_PARTICIPANT_STATUSES.contains(p.getStatus());
            if (attending) total++;
            if (isAttendingDriver(p)) confirmedDrivers++;
            if (PASSENGER_NEEDS_RIDE_STATES.contains(p.getStatus())
                    && p.getRole() == ParticipantRole.PASSENGER) passengers++;
            if (p.getStatus() == ParticipantStatus.REQUESTED) pending++;
        }
        return new EventDashboardSummary(
                event.getId(), event.getTitle(), event.getEventTime(), event.getStatus(),
                total, confirmedDrivers, pending, passengers);
    }

    private List<EventResponse> mapWithCounts(List<EventEntity> events) {
        return mapWithCounts(events, Map.of());
    }

    private List<EventResponse> mapWithCounts(List<EventEntity> events,
                                              Map<UUID, EventParticipantEntity> viewerRowByEventId) {
        if (events.isEmpty()) {
            return List.of();
        }
        Set<UUID> ids = events.stream().map(EventEntity::getId).collect(Collectors.toSet());
        Map<UUID, Long> counts = new HashMap<>();
        participantRepository.countParticipantsByEventIds(ids, NON_ATTENDING_PARTICIPANT_STATUSES)
                .forEach(p -> counts.put(p.getEventId(), p.getTotal()));
        return events.stream()
                .map(e -> {
                    EventParticipantEntity viewerRow = viewerRowByEventId.get(e.getId());
                    ParticipantRole viewerRole = viewerRow != null ? viewerRow.getRole() : null;
                    ParticipantStatus viewerStatus = viewerRow != null ? viewerRow.getStatus() : null;
                    return eventMapper.toResponse(
                            e,
                            counts.getOrDefault(e.getId(), 0L).intValue(),
                            viewerRole,
                            viewerStatus);
                })
                .toList();
    }

    /** Drivers who accepted and remain part of the event, including after trip completion. */
    private static boolean isAttendingDriver(EventParticipantEntity p) {
        return p.getRole() == ParticipantRole.DRIVER
                && !NON_ATTENDING_PARTICIPANT_STATUSES.contains(p.getStatus());
    }
}
