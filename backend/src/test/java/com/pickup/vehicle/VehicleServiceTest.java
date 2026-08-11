package com.pickup.vehicle;

import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.contact.ContactEntity;
import com.pickup.contact.ContactService;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripRepository;
import com.pickup.vehicle.dto.CreateVehicleRequest;
import com.pickup.vehicle.dto.UpdateVehicleRequest;
import com.pickup.vehicle.dto.VehicleResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VehicleServiceTest {

    private static final UUID ORGANIZER_ID = UUID.randomUUID();
    private static final UUID CONTACT_ID = UUID.randomUUID();
    private static final UUID VEHICLE_ID = UUID.randomUUID();

    @Mock
    private VehicleRepository vehicleRepository;
    @Mock
    private ContactService contactService;
    @Mock
    private TripRepository tripRepository;
    @Mock
    private EventParticipantRepository participantRepository;

    private VehicleService vehicleService;
    private ContactEntity contact;

    @BeforeEach
    void setUp() {
        vehicleService = new VehicleService(
                vehicleRepository, contactService, tripRepository, participantRepository, new VehicleMapper());
        contact = ContactEntity.builder().id(CONTACT_ID).name("Craig").build();
    }

    @Test
    void createForContact_savesVehicleOwnedByContact() {
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        when(vehicleRepository.save(any(VehicleEntity.class))).thenAnswer(inv -> {
            VehicleEntity v = inv.getArgument(0);
            v.setId(VEHICLE_ID);
            return v;
        });

        VehicleResponse response = vehicleService.createForContact(ORGANIZER_ID, CONTACT_ID,
                new CreateVehicleRequest("Craig's Honda", "Honda", "Civic", "blue", "B9912", 4, null));

        assertEquals(CONTACT_ID, response.contactId());
        assertEquals(4, response.seats());
        assertEquals("Craig's Honda", response.label());
    }

    @Test
    void listForContact_requiresActiveContactFirst() {
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID))
                .thenThrow(new NotFoundException("Contact not found: " + CONTACT_ID));

        assertThrows(NotFoundException.class,
                () -> vehicleService.listForContact(ORGANIZER_ID, CONTACT_ID));
        verify(vehicleRepository, never()).findAllByContactIdOrderByCreatedAtAsc(any());
    }

    @Test
    void updateVehicle_rejectsSeatChangeWhenReferencedByTrip() {
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        VehicleEntity vehicle = VehicleEntity.builder()
                .id(VEHICLE_ID).contact(contact).make("Honda").model("Civic").seats(4).build();
        when(vehicleRepository.findByIdAndContactId(VEHICLE_ID, CONTACT_ID)).thenReturn(Optional.of(vehicle));
        when(tripRepository.existsByVehicleId(VEHICLE_ID)).thenReturn(true);

        UpdateVehicleRequest request = new UpdateVehicleRequest(null, null, null, null, null, 5, null);

        assertThrows(ConflictException.class,
                () -> vehicleService.updateVehicle(ORGANIZER_ID, CONTACT_ID, VEHICLE_ID, request));
    }

    @Test
    void updateVehicle_throwsNotFoundWhenVehicleBelongsToDifferentContact() {
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        when(vehicleRepository.findByIdAndContactId(VEHICLE_ID, CONTACT_ID)).thenReturn(Optional.empty());

        UpdateVehicleRequest request = new UpdateVehicleRequest(null, null, null, null, null, null, null);

        assertThrows(NotFoundException.class,
                () -> vehicleService.updateVehicle(ORGANIZER_ID, CONTACT_ID, VEHICLE_ID, request));
    }

    @Test
    void deleteVehicle_blockedWhenReferencedByTrip() {
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        VehicleEntity vehicle = VehicleEntity.builder()
                .id(VEHICLE_ID).contact(contact).make("Honda").model("Civic").seats(4).build();
        when(vehicleRepository.findByIdAndContactId(VEHICLE_ID, CONTACT_ID)).thenReturn(Optional.of(vehicle));
        when(tripRepository.existsByVehicleId(VEHICLE_ID)).thenReturn(true);

        assertThrows(ConflictException.class,
                () -> vehicleService.deleteVehicle(ORGANIZER_ID, CONTACT_ID, VEHICLE_ID));
    }

    @Test
    void deleteVehicle_clearsParticipantLinkageThenDeletes() {
        when(contactService.requireActiveContact(ORGANIZER_ID, CONTACT_ID)).thenReturn(contact);
        VehicleEntity vehicle = VehicleEntity.builder()
                .id(VEHICLE_ID).contact(contact).make("Honda").model("Civic").seats(4).build();
        when(vehicleRepository.findByIdAndContactId(VEHICLE_ID, CONTACT_ID)).thenReturn(Optional.of(vehicle));
        when(tripRepository.existsByVehicleId(VEHICLE_ID)).thenReturn(false);

        vehicleService.deleteVehicle(ORGANIZER_ID, CONTACT_ID, VEHICLE_ID);

        verify(participantRepository).clearVehicleByVehicleId(VEHICLE_ID);
        verify(vehicleRepository).delete(vehicle);
    }
}
