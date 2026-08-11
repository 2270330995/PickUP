package com.pickup.vehicle;

import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.contact.ContactEntity;
import com.pickup.contact.ContactService;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripRepository;
import com.pickup.vehicle.dto.CreateVehicleRequest;
import com.pickup.vehicle.dto.UpdateVehicleRequest;
import com.pickup.vehicle.dto.VehicleResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Phase 4D-1: vehicles are owned by an organizer's {@link ContactEntity}, not a
 * driver's own {@code User} account (there are no shadow users). All mutation
 * entrypoints are contact-scoped and re-verify organizer ownership of the contact.
 */
@Service
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final ContactService contactService;
    private final TripRepository tripRepository;
    private final EventParticipantRepository participantRepository;
    private final VehicleMapper vehicleMapper;

    public VehicleService(VehicleRepository vehicleRepository,
                          ContactService contactService,
                          TripRepository tripRepository,
                          EventParticipantRepository participantRepository,
                          VehicleMapper vehicleMapper) {
        this.vehicleRepository = vehicleRepository;
        this.contactService = contactService;
        this.tripRepository = tripRepository;
        this.participantRepository = participantRepository;
        this.vehicleMapper = vehicleMapper;
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> listForContact(UUID organizerId, UUID contactId) {
        contactService.requireActiveContact(organizerId, contactId);
        return vehicleRepository.findAllByContactIdOrderByCreatedAtAsc(contactId).stream()
                .map(vehicleMapper::toResponse)
                .toList();
    }

    @Transactional
    public VehicleResponse createForContact(UUID organizerId, UUID contactId, CreateVehicleRequest request) {
        ContactEntity contact = contactService.requireActiveContact(organizerId, contactId);
        VehicleEntity vehicle = VehicleEntity.builder()
                .contact(contact)
                .label(normalizeOptional(request.label()))
                .make(request.make().trim())
                .model(request.model().trim())
                .color(normalizeOptional(request.color()))
                .plate(normalizeOptional(request.plate()))
                .seats(request.seats())
                .notes(normalizeOptional(request.notes()))
                .build();
        vehicle = vehicleRepository.save(vehicle);
        return vehicleMapper.toResponse(vehicle);
    }

    @Transactional
    public VehicleResponse updateVehicle(UUID organizerId,
                                         UUID contactId,
                                         UUID vehicleId,
                                         UpdateVehicleRequest request) {
        contactService.requireActiveContact(organizerId, contactId);
        VehicleEntity vehicle = requireOwnedByContact(vehicleId, contactId);
        if (request.label() != null) {
            vehicle.setLabel(normalizeOptional(request.label()));
        }
        if (request.make() != null && !request.make().isBlank()) {
            vehicle.setMake(request.make().trim());
        }
        if (request.model() != null && !request.model().isBlank()) {
            vehicle.setModel(request.model().trim());
        }
        if (request.color() != null) {
            vehicle.setColor(normalizeOptional(request.color()));
        }
        if (request.plate() != null) {
            vehicle.setPlate(normalizeOptional(request.plate()));
        }
        if (request.notes() != null) {
            vehicle.setNotes(normalizeOptional(request.notes()));
        }
        if (request.seats() != null) {
            if (tripRepository.existsByVehicleId(vehicleId)) {
                throw new ConflictException(
                        "Cannot change seat count while this vehicle is referenced by an existing trip");
            }
            vehicle.setSeats(request.seats());
        }
        return vehicleMapper.toResponse(vehicle);
    }

    @Transactional
    public void deleteVehicle(UUID organizerId, UUID contactId, UUID vehicleId) {
        contactService.requireActiveContact(organizerId, contactId);
        VehicleEntity vehicle = requireOwnedByContact(vehicleId, contactId);
        if (tripRepository.existsByVehicleId(vehicleId)) {
            throw new ConflictException(
                    "Vehicle is referenced by one or more trips and cannot be deleted");
        }
        // Detach any per-event driver linkages first so the FK constraint stays clean.
        participantRepository.clearVehicleByVehicleId(vehicleId);
        vehicleRepository.delete(vehicle);
    }

    public VehicleEntity loadOrThrow(UUID vehicleId) {
        return vehicleRepository.findById(vehicleId)
                .orElseThrow(() -> NotFoundException.of("Vehicle", vehicleId));
    }

    /**
     * Organizer-owns-via-contact authorization, used by organizer-driven participant
     * vehicle selection (Phase 4D-2+). Legacy self-service driver flows that call this
     * with their own user id (not an organizer) will fail closed, which is expected:
     * that flow is hidden from the primary UI during this pivot.
     */
    public VehicleEntity requireOwnedByOrganizer(UUID vehicleId, UUID organizerId) {
        VehicleEntity vehicle = loadOrThrow(vehicleId);
        if (!vehicle.getContact().getOrganizer().getId().equals(organizerId)) {
            throw new ForbiddenException("Vehicle does not belong to a contact owned by the current user");
        }
        return vehicle;
    }

    /**
     * Verifies the vehicle belongs to the given contact (not just to the organizer's
     * roster in general). Used by organizer-driven participant vehicle selection
     * (Phase 4D-2+) where the vehicle must belong to the specific contact being added.
     */
    public VehicleEntity requireOwnedByContact(UUID vehicleId, UUID contactId) {
        return vehicleRepository.findByIdAndContactId(vehicleId, contactId)
                .orElseThrow(() -> NotFoundException.of("Vehicle", vehicleId));
    }

    private static String normalizeOptional(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
