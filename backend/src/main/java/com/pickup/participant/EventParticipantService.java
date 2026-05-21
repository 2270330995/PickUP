package com.pickup.participant;

import com.pickup.common.enums.EventStatus;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.event.EventEntity;
import com.pickup.event.EventService;
import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.JoinEventRequest;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class EventParticipantService {

    private static final Set<ParticipantRole> SELF_JOIN_ROLES =
            EnumSet.of(ParticipantRole.DRIVER, ParticipantRole.PASSENGER, ParticipantRole.INDEPENDENT_ATTENDEE);
    private static final Set<ParticipantStatus> CANCELLABLE_STATES =
            EnumSet.of(ParticipantStatus.REQUESTED, ParticipantStatus.APPROVED, ParticipantStatus.CONFIRMED);

    private final EventParticipantRepository participantRepository;
    private final EventService eventService;
    private final UserRepository userRepository;
    private final EventParticipantMapper mapper;

    public EventParticipantService(EventParticipantRepository participantRepository,
                                   EventService eventService,
                                   UserRepository userRepository,
                                   EventParticipantMapper mapper) {
        this.participantRepository = participantRepository;
        this.eventService = eventService;
        this.userRepository = userRepository;
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
    public void remove(UUID organizerId, UUID eventId, UUID participantId) {
        EventParticipantEntity participant = loadParticipant(eventId, participantId);
        eventService.requireOrganizer(participant.getEvent(), organizerId);
        if (participant.getRole() == ParticipantRole.ORGANIZER) {
            throw new ConflictException("Organizer participant row cannot be removed; cancel the event instead");
        }
        participantRepository.delete(participant);
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
        if (!participant.getUser().getId().equals(currentUserId)) {
            throw new ForbiddenException("Only the participant themselves may perform this action");
        }
    }

    private void assertStatusIn(EventParticipantEntity participant, Set<ParticipantStatus> allowed) {
        if (!allowed.contains(participant.getStatus())) {
            throw new ConflictException(
                    "Cannot transition from " + participant.getStatus() + "; expected one of " + allowed);
        }
    }
}
