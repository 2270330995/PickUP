package com.pickup.contact;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.exception.BadRequestException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.common.geo.GeoLocationValidator;
import com.pickup.contact.dto.ContactResponse;
import com.pickup.contact.dto.CreateContactRequest;
import com.pickup.contact.dto.UpdateContactRequest;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import com.pickup.vehicle.VehicleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class ContactService {

    private final ContactRepository contactRepository;
    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;
    private final ContactMapper contactMapper;

    public ContactService(ContactRepository contactRepository,
                          UserRepository userRepository,
                          VehicleRepository vehicleRepository,
                          ContactMapper contactMapper) {
        this.contactRepository = contactRepository;
        this.userRepository = userRepository;
        this.vehicleRepository = vehicleRepository;
        this.contactMapper = contactMapper;
    }

    @Transactional
    public ContactResponse createContact(UUID organizerId, CreateContactRequest request) {
        UserEntity organizer = userRepository.findById(organizerId)
                .orElseThrow(() -> NotFoundException.of("User", organizerId));
        validatePreferredRole(request.preferredRole());
        GeoLocationValidator.requireCompleteOrAbsent(
                request.defaultAddress(), request.defaultLat(), request.defaultLng(), "Default location");

        ContactEntity contact = ContactEntity.builder()
                .organizer(organizer)
                .name(request.name().trim())
                .phone(normalizeOptional(request.phone()))
                .email(normalizeOptional(request.email()))
                .defaultAddress(normalizeOptional(request.defaultAddress()))
                .defaultLat(request.defaultLat())
                .defaultLng(request.defaultLng())
                .notes(normalizeOptional(request.notes()))
                .preferredRole(request.preferredRole())
                .build();
        contact = contactRepository.save(contact);
        return contactMapper.toResponse(contact, 0);
    }

    @Transactional(readOnly = true)
    public List<ContactResponse> listContacts(UUID organizerId) {
        return contactRepository.findAllByOrganizerIdAndArchivedAtIsNullOrderByNameAsc(organizerId).stream()
                .map(c -> contactMapper.toResponse(c, vehicleCount(c.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public ContactResponse getContact(UUID organizerId, UUID contactId) {
        ContactEntity contact = requireActiveContact(organizerId, contactId);
        return contactMapper.toResponse(contact, vehicleCount(contact.getId()));
    }

    @Transactional
    public ContactResponse updateContact(UUID organizerId, UUID contactId, UpdateContactRequest request) {
        ContactEntity contact = requireActiveContact(organizerId, contactId);
        if (request.name() != null && !request.name().isBlank()) {
            contact.setName(request.name().trim());
        }
        if (request.phone() != null) {
            contact.setPhone(normalizeOptional(request.phone()));
        }
        if (request.email() != null) {
            contact.setEmail(normalizeOptional(request.email()));
        }
        boolean locationTouched = request.defaultAddress() != null
                || request.defaultLat() != null
                || request.defaultLng() != null;
        if (request.defaultAddress() != null) {
            contact.setDefaultAddress(normalizeOptional(request.defaultAddress()));
        }
        if (request.defaultLat() != null) {
            contact.setDefaultLat(request.defaultLat());
        }
        if (request.defaultLng() != null) {
            contact.setDefaultLng(request.defaultLng());
        }
        if (locationTouched) {
            GeoLocationValidator.requireCompleteOrAbsent(
                    contact.getDefaultAddress(), contact.getDefaultLat(), contact.getDefaultLng(),
                    "Default location");
        }
        if (request.notes() != null) {
            contact.setNotes(normalizeOptional(request.notes()));
        }
        if (request.preferredRole() != null) {
            validatePreferredRole(request.preferredRole());
            contact.setPreferredRole(request.preferredRole());
        }
        return contactMapper.toResponse(contact, vehicleCount(contact.getId()));
    }

    /** Soft-archive. Idempotent: archiving an already-archived contact is a no-op success. */
    @Transactional
    public void archiveContact(UUID organizerId, UUID contactId) {
        ContactEntity contact = contactRepository.findByIdAndOrganizerId(contactId, organizerId)
                .orElseThrow(() -> NotFoundException.of("Contact", contactId));
        if (contact.getArchivedAt() == null) {
            contact.setArchivedAt(Instant.now());
        }
    }

    /** Loads a non-archived contact owned by {@code organizerId}, or throws 404. */
    @Transactional(readOnly = true)
    public ContactEntity requireActiveContact(UUID organizerId, UUID contactId) {
        ContactEntity contact = contactRepository.findByIdAndOrganizerId(contactId, organizerId)
                .orElseThrow(() -> NotFoundException.of("Contact", contactId));
        if (contact.getArchivedAt() != null) {
            throw NotFoundException.of("Contact", contactId);
        }
        return contact;
    }

    private int vehicleCount(UUID contactId) {
        return vehicleRepository.findAllByContactIdOrderByCreatedAtAsc(contactId).size();
    }

    private void validatePreferredRole(ParticipantRole role) {
        if (role == ParticipantRole.ORGANIZER) {
            throw new BadRequestException("preferredRole cannot be ORGANIZER");
        }
    }

    private static String normalizeOptional(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
