package com.pickup.participant;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.contact.ContactEntity;
import com.pickup.contact.ContactService;
import com.pickup.event.EventEntity;
import com.pickup.event.EventService;
import com.pickup.participant.dto.AddContactParticipantRequest;
import com.pickup.participant.dto.AddContactsFromRosterRequest;
import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.OrganizerUpdateParticipantRequest;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import com.pickup.vehicle.VehicleService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EventParticipantServiceTest {

    private static final UUID ORGANIZER_ID = UUID.randomUUID();
    private static final UUID EVENT_ID = UUID.randomUUID();
    private static final UUID CONTACT_ID = UUID.randomUUID();
    private static final UUID VEHICLE_ID = UUID.randomUUID();
    private static final UUID PARTICIPANT_ID = UUID.randomUUID();

    @Mock private EventParticipantRepository participantRepository;
    @Mock private EventService eventService;
    @Mock private UserRepository userRepository;
    @Mock private ContactService contactService;
    @Mock private VehicleService vehicleService;

    private EventParticipantService service;
    private EventEntity event;
    private ContactEntity contact;

    @BeforeEach
    void setUp() {
        service = new EventParticipantService(
                participantRepository, eventService, userRepository, contactService,
                vehicleService, new EventParticipantMapper());

        UserEntity organizer = UserEntity.builder().id(ORGANIZER_ID).fullName("Org").email("org@test.com").build();
        event = EventEntity.builder().id(EVENT_ID).organizer(organizer).title("Demo").build();
        contact = ContactEntity.builder().id(CONTACT_ID).name("Dell")
                .defaultAddress("123 Main St").defaultLat(37.0).defaultLng(-122.0).build();
    }

    @Test
    void addFromContact_happyPath_createsReadyParticipantWithCopiedDefaultLocation() {
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        when(participantRepository.findByEventIdAndContactId(EVENT_ID, CONTACT_ID))
                .thenReturn(Optional.empty());
        when(participantRepository.save(any(EventParticipantEntity.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        EventParticipantResponse response = service.addFromContact(ORGANIZER_ID, EVENT_ID,
                new AddContactParticipantRequest(CONTACT_ID, ParticipantRole.PASSENGER, null, null, null, null));

        assertEquals(ParticipantStatus.READY, response.status());
        assertEquals(CONTACT_ID, response.contactId());
        assertEquals("123 Main St", response.pickupAddress());
        assertEquals(37.0, response.pickupLat());
        assertEquals(-122.0, response.pickupLng());
    }

    @Test
    void addFromContact_duplicateActiveContact_throwsConflict() {
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        EventParticipantEntity existing = EventParticipantEntity.builder()
                .id(PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.READY).build();
        when(participantRepository.findByEventIdAndContactId(EVENT_ID, CONTACT_ID))
                .thenReturn(Optional.of(existing));

        assertThrows(ConflictException.class, () -> service.addFromContact(ORGANIZER_ID, EVENT_ID,
                new AddContactParticipantRequest(CONTACT_ID, ParticipantRole.PASSENGER, null, null, null, null)));
        verify(participantRepository, never()).save(any());
    }

    @Test
    void addFromContact_reactivatesPreviouslyCancelledParticipant() {
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        EventParticipantEntity cancelled = EventParticipantEntity.builder()
                .id(PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.CANCELLED).build();
        when(participantRepository.findByEventIdAndContactId(EVENT_ID, CONTACT_ID))
                .thenReturn(Optional.of(cancelled));
        when(participantRepository.save(any(EventParticipantEntity.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        EventParticipantResponse response = service.addFromContact(ORGANIZER_ID, EVENT_ID,
                new AddContactParticipantRequest(CONTACT_ID, ParticipantRole.PASSENGER, null, null, null, null));

        assertEquals(PARTICIPANT_ID, response.id());
        assertEquals(ParticipantStatus.READY, response.status());
    }

    @Test
    void addFromContact_vehicleFromDifferentContact_isRejected() {
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        when(vehicleService.requireOwnedByContact(VEHICLE_ID, CONTACT_ID))
                .thenThrow(new NotFoundException("Vehicle not found: " + VEHICLE_ID));

        assertThrows(NotFoundException.class, () -> service.addFromContact(ORGANIZER_ID, EVENT_ID,
                new AddContactParticipantRequest(CONTACT_ID, ParticipantRole.DRIVER, VEHICLE_ID, null, null, null)));
        verify(participantRepository, never()).save(any());
    }

    @Test
    void addFromContact_vehicleOnNonDriverRole_throwsConflict() {
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);

        assertThrows(ConflictException.class, () -> service.addFromContact(ORGANIZER_ID, EVENT_ID,
                new AddContactParticipantRequest(CONTACT_ID, ParticipantRole.PASSENGER, VEHICLE_ID, null, null, null)));
    }

    @Test
    void addFromContacts_duplicateContactWithinBatch_rejectedBeforeSecondEntrySaves() {
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        when(participantRepository.findByEventIdAndContactId(EVENT_ID, CONTACT_ID))
                .thenReturn(Optional.empty());
        when(participantRepository.save(any(EventParticipantEntity.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        AddContactParticipantRequest entry =
                new AddContactParticipantRequest(CONTACT_ID, ParticipantRole.PASSENGER, null, null, null, null);
        AddContactsFromRosterRequest batch =
                new AddContactsFromRosterRequest(List.of(entry, entry));

        // The second (duplicate) entry is rejected before it is ever saved; the real
        // atomic rollback of the first entry's save is enforced by @Transactional in
        // production, which is outside the scope of this repository-mocked unit test.
        assertThrows(ConflictException.class, () -> service.addFromContacts(ORGANIZER_ID, EVENT_ID, batch));
        verify(participantRepository, times(1)).save(any());
    }

    @Test
    void organizerUpdate_changesRoleAndPickup() {
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .id(PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.READY).build();
        when(participantRepository.findById(PARTICIPANT_ID)).thenReturn(Optional.of(participant));

        EventParticipantResponse response = service.organizerUpdate(ORGANIZER_ID, EVENT_ID, PARTICIPANT_ID,
                new OrganizerUpdateParticipantRequest(
                        ParticipantRole.INDEPENDENT_ATTENDEE, "456 Oak Ave", 37.1, -122.1));

        assertEquals(ParticipantRole.INDEPENDENT_ATTENDEE, response.role());
        assertEquals("456 Oak Ave", response.pickupAddress());
    }

    @Test
    void organizerUpdate_rejectsWhenParticipantAlreadyAssigned() {
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .id(PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.ASSIGNED).build();
        when(participantRepository.findById(PARTICIPANT_ID)).thenReturn(Optional.of(participant));

        assertThrows(ConflictException.class, () -> service.organizerUpdate(ORGANIZER_ID, EVENT_ID, PARTICIPANT_ID,
                new OrganizerUpdateParticipantRequest(ParticipantRole.DRIVER, null, null, null)));
    }

    @Test
    void remove_softCancelsRatherThanDeleting() {
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .id(PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.READY).build();
        when(participantRepository.findById(PARTICIPANT_ID)).thenReturn(Optional.of(participant));

        service.remove(ORGANIZER_ID, EVENT_ID, PARTICIPANT_ID);

        assertEquals(ParticipantStatus.CANCELLED, participant.getStatus());
        verify(participantRepository, never()).delete(any());
        verify(participantRepository, never()).deleteById(any());
    }

    @Test
    void remove_blockedWhileAssignedToATrip() {
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .id(PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.DRIVER).status(ParticipantStatus.ASSIGNED).build();
        when(participantRepository.findById(PARTICIPANT_ID)).thenReturn(Optional.of(participant));

        assertThrows(ConflictException.class, () -> service.remove(ORGANIZER_ID, EVENT_ID, PARTICIPANT_ID));
        assertEquals(ParticipantStatus.ASSIGNED, participant.getStatus());
    }
}
