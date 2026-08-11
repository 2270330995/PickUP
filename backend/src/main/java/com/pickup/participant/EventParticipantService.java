package com.pickup.participant;

import com.pickup.common.enums.EventStatus;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.common.geo.GeoLocationValidator;
import com.pickup.contact.ContactEntity;
import com.pickup.contact.ContactService;
import com.pickup.event.EventEntity;
import com.pickup.event.EventService;
import com.pickup.participant.dto.AddContactParticipantRequest;
import com.pickup.participant.dto.AddContactsFromRosterRequest;
import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.JoinEventRequest;
import com.pickup.participant.dto.OrganizerUpdateParticipantRequest;
import com.pickup.participant.dto.UpdateParticipantPickupRequest;
import com.pickup.participant.dto.UpdateParticipantVehicleRequest;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import com.pickup.vehicle.VehicleEntity;
import com.pickup.vehicle.VehicleService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class EventParticipantService {

    private static final Set<ParticipantRole> SELF_JOIN_ROLES =
            EnumSet.of(ParticipantRole.DRIVER, ParticipantRole.PASSENGER, ParticipantRole.INDEPENDENT_ATTENDEE);
    private static final Set<ParticipantStatus> CANCELLABLE_STATES =
            EnumSet.of(ParticipantStatus.REQUESTED, ParticipantStatus.APPROVED, ParticipantStatus.CONFIRMED);
    /** Statuses in which a driver may attach or change their vehicle for an event. */
    private static final Set<ParticipantStatus> VEHICLE_EDITABLE_STATES =
            EnumSet.of(ParticipantStatus.READY, ParticipantStatus.APPROVED,
                    ParticipantStatus.CONFIRMED, ParticipantStatus.ASSIGNED);
    /** Statuses in which a driver may set or change their trip start location. */
    private static final Set<ParticipantStatus> TRIP_START_EDITABLE_STATES =
            EnumSet.of(ParticipantStatus.REQUESTED, ParticipantStatus.APPROVED, ParticipantStatus.CONFIRMED);
    /** Statuses in which a passenger may set or change their pickup location. */
    private static final Set<ParticipantStatus> PICKUP_EDITABLE_STATES =
            EnumSet.of(ParticipantStatus.REQUESTED, ParticipantStatus.APPROVED, ParticipantStatus.CONFIRMED);
    /** Statuses in which the organizer may edit a Contact-backed (or legacy) participant. */
    private static final Set<ParticipantStatus> ORGANIZER_EDITABLE_STATES =
            EnumSet.of(ParticipantStatus.READY, ParticipantStatus.REQUESTED,
                    ParticipantStatus.APPROVED, ParticipantStatus.CONFIRMED);
    /** Statuses an organizer may remove a participant from (ASSIGNED must be unassigned first). */
    private static final Set<ParticipantStatus> REMOVABLE_STATES =
            EnumSet.of(ParticipantStatus.INVITED, ParticipantStatus.REQUESTED, ParticipantStatus.APPROVED,
                    ParticipantStatus.REJECTED, ParticipantStatus.CONFIRMED, ParticipantStatus.READY,
                    ParticipantStatus.CHECKED_IN, ParticipantStatus.PICKED_UP, ParticipantStatus.ARRIVED,
                    ParticipantStatus.NO_SHOW);

    private final EventParticipantRepository participantRepository;
    private final EventService eventService;
    private final UserRepository userRepository;
    private final ContactService contactService;
    private final VehicleService vehicleService;
    private final EventParticipantMapper mapper;

    public EventParticipantService(EventParticipantRepository participantRepository,
                                   EventService eventService,
                                   UserRepository userRepository,
                                   ContactService contactService,
                                   VehicleService vehicleService,
                                   EventParticipantMapper mapper) {
        this.participantRepository = participantRepository;
        this.eventService = eventService;
        this.userRepository = userRepository;
        this.contactService = contactService;
        this.vehicleService = vehicleService;
        this.mapper = mapper;
    }

    @Transactional
    public EventParticipantResponse selfJoin(UUID userId, UUID eventId, JoinEventRequest request) {
        if (!SELF_JOIN_ROLES.contains(request.role())) {
            throw new ConflictException(
                    "Only DRIVER, PASSENGER, or INDEPENDENT_ATTENDEE may self-join (got " + request.role() + ")");
        }
        EventEntity event = eventService.loadOrThrow(eventId);
        if (event.getStatus() != EventStatus.OPEN) {
            throw new ConflictException("Event is not open for joining (status " + event.getStatus() + ")");
        }
        if (participantRepository.existsByEventIdAndUserId(eventId, userId)) {
            throw new ConflictException("You are already a participant of this event");
        }
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> NotFoundException.of("User", userId));

        GeoLocationValidator.requireCompleteOrAbsent(
                request.pickupAddress(),
                request.pickupLat(),
                request.pickupLng(),
                "Location");

        EventParticipantEntity participant = EventParticipantEntity.builder()
                .event(event)
                .user(user)
                .role(request.role())
                .status(ParticipantStatus.REQUESTED)
                .pickupAddress(request.pickupAddress())
                .pickupLat(request.pickupLat())
                .pickupLng(request.pickupLng())
                .build();
        participant = participantRepository.save(participant);
        return mapper.toResponse(participant);
    }

    /**
     * Organizer adds a single Contact to the event as a READY participant. If the
     * contact was previously added and then removed (CANCELLED), the existing row
     * is reactivated rather than creating a duplicate.
     */
    @Transactional
    public EventParticipantResponse addFromContact(UUID organizerId, UUID eventId, AddContactParticipantRequest request) {
        EventEntity event = eventService.loadOrThrow(eventId);
        eventService.requireOrganizer(event, organizerId);
        EventParticipantEntity participant = addOrReactivate(organizerId, event, request, new HashSet<>());
        return mapper.toResponse(participant);
    }

    /**
     * Organizer adds multiple Contacts to the event in one atomic operation. If any
     * entry fails validation or duplicates another (in-request or already-active),
     * the entire batch is rolled back.
     */
    @Transactional
    public List<EventParticipantResponse> addFromContacts(UUID organizerId,
                                                           UUID eventId,
                                                           AddContactsFromRosterRequest request) {
        EventEntity event = eventService.loadOrThrow(eventId);
        eventService.requireOrganizer(event, organizerId);
        Set<UUID> seenContactIds = new HashSet<>();
        List<EventParticipantEntity> results = new ArrayList<>(request.entries().size());
        for (AddContactParticipantRequest entry : request.entries()) {
            results.add(addOrReactivate(organizerId, event, entry, seenContactIds));
        }
        return results.stream().map(mapper::toResponse).toList();
    }

    private EventParticipantEntity addOrReactivate(UUID organizerId,
                                                    EventEntity event,
                                                    AddContactParticipantRequest request,
                                                    Set<UUID> seenContactIds) {
        if (request.role() == ParticipantRole.ORGANIZER) {
            throw new ConflictException("Cannot add a contact as ORGANIZER");
        }
        if (!seenContactIds.add(request.contactId())) {
            throw new ConflictException("Contact " + request.contactId() + " appears more than once in this batch");
        }
        ContactEntity contact = contactService.requireActiveContact(organizerId, request.contactId());
        GeoLocationValidator.requireCompleteOrAbsent(
                request.pickupAddress(), request.pickupLat(), request.pickupLng(), "Pickup");

        VehicleEntity vehicle = null;
        if (request.vehicleId() != null) {
            if (request.role() != ParticipantRole.DRIVER) {
                throw new ConflictException("Only DRIVER participants may have a vehicle selected");
            }
            vehicle = vehicleService.requireOwnedByContact(request.vehicleId(), contact.getId());
        }

        EventParticipantEntity participant = participantRepository
                .findByEventIdAndContactId(event.getId(), contact.getId())
                .orElse(null);
        if (participant != null) {
            if (participant.getStatus() != ParticipantStatus.CANCELLED) {
                throw new ConflictException("Contact " + contact.getId() + " is already a participant of this event");
            }
            participant.setRole(request.role());
            participant.setStatus(ParticipantStatus.READY);
            participant.setVehicle(vehicle);
        } else {
            participant = EventParticipantEntity.builder()
                    .event(event)
                    .contact(contact)
                    .role(request.role())
                    .status(ParticipantStatus.READY)
                    .vehicle(vehicle)
                    .build();
        }
        applyPickupFromRequestOrContactDefault(participant, contact, request);
        return participantRepository.save(participant);
    }

    /**
     * Copies the contact's default location onto the participant only at creation
     * (or reactivation) time. Per product rule, later organizer edits are event-local
     * and never write back to the Contact, and this copy never re-runs afterward.
     */
    private void applyPickupFromRequestOrContactDefault(EventParticipantEntity participant,
                                                        ContactEntity contact,
                                                        AddContactParticipantRequest request) {
        if (request.pickupAddress() != null) {
            participant.setPickupAddress(request.pickupAddress().trim());
            participant.setPickupLat(request.pickupLat());
            participant.setPickupLng(request.pickupLng());
        } else if (contact.getDefaultAddress() != null) {
            participant.setPickupAddress(contact.getDefaultAddress());
            participant.setPickupLat(contact.getDefaultLat());
            participant.setPickupLng(contact.getDefaultLng());
        } else {
            participant.setPickupAddress(null);
            participant.setPickupLat(null);
            participant.setPickupLng(null);
        }
    }

    @Transactional(readOnly = true)
    public List<EventParticipantResponse> listForEvent(UUID eventId) {
        eventService.loadOrThrow(eventId); // ensures 404 if event missing
        return participantRepository.findAllByEventIdOrderByCreatedAtAsc(eventId).stream()
                .map(mapper::toResponse)
                .toList();
    }

    @Transactional
    public EventParticipantResponse approve(UUID organizerId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        eventService.requireOrganizer(participant.getEvent(), organizerId);
        assertStatusIn(participant, EnumSet.of(ParticipantStatus.REQUESTED));
        participant.setStatus(ParticipantStatus.APPROVED);
        return mapper.toResponse(participant);
    }

    @Transactional
    public EventParticipantResponse reject(UUID organizerId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        eventService.requireOrganizer(participant.getEvent(), organizerId);
        assertStatusIn(participant, EnumSet.of(ParticipantStatus.REQUESTED));
        participant.setStatus(ParticipantStatus.REJECTED);
        return mapper.toResponse(participant);
    }

    @Transactional
    public EventParticipantResponse confirm(UUID currentUserId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        requireParticipantOwner(participant, currentUserId);
        assertStatusIn(participant, EnumSet.of(ParticipantStatus.APPROVED));
        participant.setStatus(ParticipantStatus.CONFIRMED);
        return mapper.toResponse(participant);
    }

    @Transactional
    public EventParticipantResponse cancel(UUID currentUserId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        requireParticipantOwner(participant, currentUserId);
        if (participant.getRole() == ParticipantRole.ORGANIZER) {
            throw new ConflictException("Organizer cannot cancel their own participation; cancel the event instead");
        }
        assertStatusIn(participant, CANCELLABLE_STATES);
        participant.setStatus(ParticipantStatus.CANCELLED);
        return mapper.toResponse(participant);
    }

    @Transactional
    public EventParticipantResponse rejoin(UUID currentUserId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        requireParticipantOwner(participant, currentUserId);
        if (participant.getStatus() != ParticipantStatus.CANCELLED) {
            throw new ConflictException(
                    "Only self-cancelled participants may rejoin (current status: " + participant.getStatus() + ")");
        }
        EventEntity event = participant.getEvent();
        if (event.getStatus() != EventStatus.OPEN) {
            throw new ConflictException("Event is no longer open for joining");
        }
        participant.setStatus(ParticipantStatus.REQUESTED);
        return mapper.toResponse(participant);
    }

    /**
     * Organizer-driven edit of a participant's per-event role and pickup location.
     * Event-local only: never writes back to the underlying Contact. Vehicle
     * selection remains the concern of {@link #setVehicle}.
     */
    @Transactional
    public EventParticipantResponse organizerUpdate(UUID organizerId,
                                                    UUID eventId,
                                                    UUID participantId,
                                                    OrganizerUpdateParticipantRequest request) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        eventService.requireOrganizer(participant.getEvent(), organizerId);
        if (participant.getRole() == ParticipantRole.ORGANIZER) {
            throw new ConflictException("Organizer participant row cannot be edited this way");
        }
        if (!ORGANIZER_EDITABLE_STATES.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Participant can only be edited in status " + ORGANIZER_EDITABLE_STATES
                            + " (current: " + participant.getStatus() + ")");
        }
        if (request.role() != null && request.role() != participant.getRole()) {
            if (request.role() == ParticipantRole.ORGANIZER) {
                throw new ConflictException("Cannot change a participant's role to ORGANIZER");
            }
            participant.setRole(request.role());
            if (request.role() != ParticipantRole.DRIVER) {
                participant.setVehicle(null);
            }
        }
        boolean pickupTouched = request.pickupAddress() != null
                || request.pickupLat() != null
                || request.pickupLng() != null;
        if (pickupTouched) {
            GeoLocationValidator.requireComplete(
                    request.pickupAddress(), request.pickupLat(), request.pickupLng(), "Pickup");
            participant.setPickupAddress(request.pickupAddress().trim());
            participant.setPickupLat(request.pickupLat());
            participant.setPickupLng(request.pickupLng());
        }
        return mapper.toResponse(participant);
    }

    /**
     * Passenger sets (or updates) their pickup location for a specific event.
     *
     * <p>Authorization: only the participant's user may call this. Domain rules:
     * <ul>
     *   <li>Participant role must be PASSENGER.</li>
     *   <li>Status must be REQUESTED, APPROVED, or CONFIRMED (not yet ASSIGNED to a trip).</li>
     * </ul>
     */
    @Transactional
    public EventParticipantResponse setPickup(UUID currentUserId,
                                            UUID eventId,
                                            UUID participantId,
                                            UpdateParticipantPickupRequest request) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        requireParticipantOwner(participant, currentUserId);
        if (participant.getRole() != ParticipantRole.PASSENGER) {
            throw new ConflictException(
                    "Only PASSENGER participants may set a pickup location (current role: "
                            + participant.getRole() + ")");
        }
        if (!PICKUP_EDITABLE_STATES.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Pickup location can only be set in status " + PICKUP_EDITABLE_STATES
                            + " (current: " + participant.getStatus() + ")");
        }
        GeoLocationValidator.requireComplete(
                request.pickupAddress(),
                request.pickupLat(),
                request.pickupLng(),
                "Pickup");
        participant.setPickupAddress(request.pickupAddress().trim());
        participant.setPickupLat(request.pickupLat());
        participant.setPickupLng(request.pickupLng());
        return mapper.toResponse(participant);
    }

    /**
     * Driver sets (or updates) their trip start location for a specific event.
     *
     * <p>For {@code DRIVER} participants, {@code pickupLat/Lng} is the route anchor
     * before the first passenger stop (Phase 4B convention).
     */
    @Transactional
    public EventParticipantResponse setTripStart(UUID currentUserId,
                                                 UUID eventId,
                                                 UUID participantId,
                                                 UpdateParticipantPickupRequest request) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        requireParticipantOwner(participant, currentUserId);
        if (participant.getRole() != ParticipantRole.DRIVER) {
            throw new ConflictException(
                    "Only DRIVER participants may set a trip start location (current role: "
                            + participant.getRole() + ")");
        }
        if (!TRIP_START_EDITABLE_STATES.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Trip start location can only be set in status " + TRIP_START_EDITABLE_STATES
                            + " (current: " + participant.getStatus() + ")");
        }
        GeoLocationValidator.requireComplete(
                request.pickupAddress(),
                request.pickupLat(),
                request.pickupLng(),
                "Trip start");
        participant.setPickupAddress(request.pickupAddress().trim());
        participant.setPickupLat(request.pickupLat());
        participant.setPickupLng(request.pickupLng());
        return mapper.toResponse(participant);
    }

    /**
     * Sets or clears the vehicle a DRIVER participant will use for this event.
     *
     * <p>Authorization: the participant's own user (legacy self-join) or the event
     * organizer (required for Contact-backed participants, which have no user login).
     * Domain rules:
     * <ul>
     *   <li>Participant role must be DRIVER.</li>
     *   <li>Status must be READY, APPROVED, CONFIRMED, or ASSIGNED.</li>
     *   <li>Vehicle (when non-null) must belong to the same Contact/organizer as the participant.</li>
     *   <li>Clearing the linkage (vehicleId = null) is rejected once the participant has
     *       been placed on a trip (status = ASSIGNED), so trips never lose their vehicle silently.</li>
     * </ul>
     */
    @Transactional
    public EventParticipantResponse setVehicle(UUID currentUserId,
                                               UUID eventId,
                                               UUID participantId,
                                               UpdateParticipantVehicleRequest request) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        requireParticipantOwnerOrOrganizer(participant, currentUserId);
        if (participant.getRole() != ParticipantRole.DRIVER) {
            throw new ConflictException(
                    "Only DRIVER participants may attach a vehicle (current role: " + participant.getRole() + ")");
        }
        if (!VEHICLE_EDITABLE_STATES.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Vehicle can only be set in status " + VEHICLE_EDITABLE_STATES
                            + " (current: " + participant.getStatus() + ")");
        }
        UUID vehicleId = request.vehicleId();
        if (vehicleId == null) {
            if (participant.getStatus() == ParticipantStatus.ASSIGNED) {
                throw new ConflictException(
                        "Cannot clear vehicle while participant is ASSIGNED to a trip");
            }
            participant.setVehicle(null);
        } else if (participant.getContact() != null) {
            VehicleEntity vehicle = vehicleService.requireOwnedByContact(vehicleId, participant.getContact().getId());
            participant.setVehicle(vehicle);
        } else {
            // Legacy self-join path: vehicles are organizer/Contact-owned (Phase 4D-1), so this
            // succeeds only when the caller is the organizer of the event.
            VehicleEntity vehicle = vehicleService.requireOwnedByOrganizer(vehicleId, currentUserId);
            participant.setVehicle(vehicle);
        }
        return mapper.toResponse(participant);
    }

    /**
     * Organizer-only soft removal: sets the participant to CANCELLED rather than
     * deleting the row, preserving historical event participation. Re-adding the
     * same Contact later reactivates this row (see {@link #addOrReactivate}).
     */
    @Transactional
    public void remove(UUID organizerId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        eventService.requireOrganizer(participant.getEvent(), organizerId);
        if (participant.getRole() == ParticipantRole.ORGANIZER) {
            throw new ConflictException("Organizer participant row cannot be removed; cancel the event instead");
        }
        if (!REMOVABLE_STATES.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Cannot remove a participant in status " + participant.getStatus()
                            + "; unassign from any trip first");
        }
        participant.setStatus(ParticipantStatus.CANCELLED);
    }

    private EventParticipantEntity loadParticipant(UUID eventId, UUID participantId) {
        EventParticipantEntity participant = participantRepository.findById(participantId)
                .orElseThrow(() -> NotFoundException.of("Participant", participantId));
        if (!participant.getEvent().getId().equals(eventId)) {
            throw NotFoundException.of("Participant", participantId);
        }
        return participant;
    }

    private void requireParticipantOwner(EventParticipantEntity participant, UUID currentUserId) {
        if (participant.getUser() == null || !participant.getUser().getId().equals(currentUserId)) {
            throw new ForbiddenException("Only the participant themselves may perform this action");
        }
    }

    private void requireParticipantOwnerOrOrganizer(EventParticipantEntity participant, UUID currentUserId) {
        boolean isOwner = participant.getUser() != null && participant.getUser().getId().equals(currentUserId);
        boolean isOrganizer = participant.getEvent().getOrganizer().getId().equals(currentUserId);
        if (!isOwner && !isOrganizer) {
            throw new ForbiddenException("Only the participant themselves or the event organizer may perform this action");
        }
    }

    private void assertStatusIn(EventParticipantEntity participant, Set<ParticipantStatus> allowed) {
        if (!allowed.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Cannot transition from " + participant.getStatus() + "; expected one of " + allowed);
        }
    }
}
