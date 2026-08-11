package com.pickup.contact;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.exception.BadRequestException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.contact.dto.ContactResponse;
import com.pickup.contact.dto.CreateContactRequest;
import com.pickup.contact.dto.UpdateContactRequest;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import com.pickup.vehicle.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContactServiceTest {

    private static final UUID ORGANIZER_ID = UUID.randomUUID();
    private static final UUID OTHER_ORGANIZER_ID = UUID.randomUUID();

    @Mock
    private ContactRepository contactRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private VehicleRepository vehicleRepository;

    private ContactService contactService;
    private UserEntity organizer;

    @BeforeEach
    void setUp() {
        contactService = new ContactService(contactRepository, userRepository, vehicleRepository, new ContactMapper());
        organizer = UserEntity.builder()
                .id(ORGANIZER_ID)
                .email("organizer@test.com")
                .passwordHash("hash")
                .fullName("Organizer")
                .build();
    }

    @Test
    void createContact_savesWithOrganizerAndDefaults() {
        when(userRepository.findById(ORGANIZER_ID)).thenReturn(Optional.of(organizer));
        when(contactRepository.save(any(ContactEntity.class))).thenAnswer(inv -> {
            ContactEntity entity = inv.getArgument(0);
            entity.setId(UUID.randomUUID());
            return entity;
        });

        CreateContactRequest request = new CreateContactRequest(
                "Craig", "555-1234", "craig@example.com",
                "100 Van Ness Ave, San Francisco, CA", 37.7759, -122.4194,
                "Usually free after 5", ParticipantRole.DRIVER);

        ContactResponse response = contactService.createContact(ORGANIZER_ID, request);

        assertEquals("Craig", response.name());
        assertEquals(ParticipantRole.DRIVER, response.preferredRole());
        assertEquals(0, response.vehicleCount());
        assertNull(response.archivedAt());
    }

    @Test
    void createContact_rejectsOrganizerAsPreferredRole() {
        when(userRepository.findById(ORGANIZER_ID)).thenReturn(Optional.of(organizer));
        CreateContactRequest request = new CreateContactRequest(
                "Craig", null, null, null, null, null, null, ParticipantRole.ORGANIZER);

        assertThrows(BadRequestException.class, () -> contactService.createContact(ORGANIZER_ID, request));
    }

    @Test
    void createContact_rejectsIncompleteDefaultLocation() {
        when(userRepository.findById(ORGANIZER_ID)).thenReturn(Optional.of(organizer));
        CreateContactRequest request = new CreateContactRequest(
                "Craig", null, null, "100 Van Ness Ave", null, null, null, null);

        assertThrows(BadRequestException.class, () -> contactService.createContact(ORGANIZER_ID, request));
    }

    @Test
    void listContacts_mapsVehicleCountPerContact() {
        ContactEntity craig = activeContact("Craig");
        when(contactRepository.findAllByOrganizerIdAndArchivedAtIsNullOrderByNameAsc(ORGANIZER_ID))
                .thenReturn(List.of(craig));
        when(vehicleRepository.findAllByContactIdOrderByCreatedAtAsc(craig.getId()))
                .thenReturn(List.of(com.pickup.vehicle.VehicleEntity.builder().build()));

        List<ContactResponse> result = contactService.listContacts(ORGANIZER_ID);

        assertEquals(1, result.size());
        assertEquals(1, result.getFirst().vehicleCount());
    }

    @Test
    void getContact_throwsNotFoundWhenArchived() {
        ContactEntity archived = activeContact("Craig");
        archived.setArchivedAt(Instant.now());
        when(contactRepository.findByIdAndOrganizerId(archived.getId(), ORGANIZER_ID))
                .thenReturn(Optional.of(archived));

        assertThrows(NotFoundException.class,
                () -> contactService.getContact(ORGANIZER_ID, archived.getId()));
    }

    @Test
    void getContact_throwsNotFoundForDifferentOrganizer() {
        UUID contactId = UUID.randomUUID();
        when(contactRepository.findByIdAndOrganizerId(contactId, OTHER_ORGANIZER_ID))
                .thenReturn(Optional.empty());

        assertThrows(NotFoundException.class,
                () -> contactService.getContact(OTHER_ORGANIZER_ID, contactId));
    }

    @Test
    void updateContact_clearsOptionalStringOnBlankValue() {
        ContactEntity craig = activeContact("Craig");
        craig.setNotes("old notes");
        when(contactRepository.findByIdAndOrganizerId(craig.getId(), ORGANIZER_ID))
                .thenReturn(Optional.of(craig));
        when(vehicleRepository.findAllByContactIdOrderByCreatedAtAsc(craig.getId())).thenReturn(List.of());

        UpdateContactRequest request = new UpdateContactRequest(
                null, null, null, null, null, null, "   ", null);
        ContactResponse response = contactService.updateContact(ORGANIZER_ID, craig.getId(), request);

        assertNull(response.notes());
    }

    @Test
    void updateContact_validatesLocationTriadWhenTouched() {
        ContactEntity craig = activeContact("Craig");
        when(contactRepository.findByIdAndOrganizerId(craig.getId(), ORGANIZER_ID))
                .thenReturn(Optional.of(craig));

        UpdateContactRequest request = new UpdateContactRequest(
                null, null, null, "New address", null, null, null, null);

        assertThrows(BadRequestException.class,
                () -> contactService.updateContact(ORGANIZER_ID, craig.getId(), request));
    }

    @Test
    void archiveContact_isIdempotent() {
        ContactEntity craig = activeContact("Craig");
        when(contactRepository.findByIdAndOrganizerId(craig.getId(), ORGANIZER_ID))
                .thenReturn(Optional.of(craig));

        contactService.archiveContact(ORGANIZER_ID, craig.getId());
        assertNotNull(craig.getArchivedAt());

        Instant firstArchivedAt = craig.getArchivedAt();
        contactService.archiveContact(ORGANIZER_ID, craig.getId());
        assertEquals(firstArchivedAt, craig.getArchivedAt());
    }

    @Test
    void requireActiveContact_throwsWhenMissing() {
        UUID contactId = UUID.randomUUID();
        when(contactRepository.findByIdAndOrganizerId(contactId, ORGANIZER_ID)).thenReturn(Optional.empty());

        assertThrows(NotFoundException.class,
                () -> contactService.requireActiveContact(ORGANIZER_ID, contactId));
    }

    private ContactEntity activeContact(String name) {
        return ContactEntity.builder()
                .id(UUID.randomUUID())
                .organizer(organizer)
                .name(name)
                .build();
    }
}
