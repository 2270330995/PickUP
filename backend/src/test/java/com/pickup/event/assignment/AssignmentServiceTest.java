package com.pickup.event.assignment;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.exception.ConflictException;
import com.pickup.contact.ContactEntity;
import com.pickup.event.EventEntity;
import com.pickup.event.EventService;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripEntity;
import com.pickup.trip.TripMapper;
import com.pickup.trip.TripRepository;
import com.pickup.trip.dto.TripResponse;
import com.pickup.trip.navigation.GoogleMapsNavigationUrlBuilder;
import com.pickup.trip.navigation.TripNavigationResolver;
import com.pickup.trip.planning.TripRouteEnrichmentService;
import com.pickup.tripstop.TripStopMapper;
import com.pickup.user.UserEntity;
import com.pickup.vehicle.VehicleEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AssignmentServiceTest {

    private static final UUID ORGANIZER_ID = UUID.randomUUID();
    private static final UUID EVENT_ID = UUID.randomUUID();
    private static final UUID DRIVER_PARTICIPANT_ID = UUID.randomUUID();
    private static final UUID PASSENGER_PARTICIPANT_ID = UUID.randomUUID();

    @Mock private EventService eventService;
    @Mock private EventParticipantRepository participantRepository;
    @Mock private TripRepository tripRepository;
    @Mock private TripRouteEnrichmentService tripRouteEnrichmentService;

    private AssignmentService service;
    private EventEntity event;
    private EventParticipantEntity contactDriver;
    private EventParticipantEntity passenger;

    @BeforeEach
    void setUp() {
        TripMapper tripMapper = new TripMapper(
                new TripStopMapper(),
                new TripNavigationResolver(new GoogleMapsNavigationUrlBuilder()));
        service = new AssignmentService(
                eventService, participantRepository, tripRepository, tripMapper, tripRouteEnrichmentService);

        UserEntity organizer = UserEntity.builder().id(ORGANIZER_ID).fullName("Org").email("org@test.com").build();
        event = EventEntity.builder().id(EVENT_ID).organizer(organizer).title("Demo")
                .destinationAddress("Destination").destinationLat(1.0).destinationLng(2.0).build();

        ContactEntity contact = ContactEntity.builder().id(UUID.randomUUID()).name("Dell").build();
        VehicleEntity vehicle = VehicleEntity.builder().id(UUID.randomUUID())
                .contact(contact).make("Honda").model("Civic").seats(4).build();
        contactDriver = EventParticipantEntity.builder()
                .id(DRIVER_PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.DRIVER).status(ParticipantStatus.READY).vehicle(vehicle).build();

        passenger = EventParticipantEntity.builder()
                .id(PASSENGER_PARTICIPANT_ID).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.READY)
                .pickupAddress("Pickup").pickupLat(1.1).pickupLng(2.1).build();

        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(participantRepository.findAllByEventIdOrderByCreatedAtAsc(EVENT_ID))
                .thenReturn(List.of(contactDriver, passenger));
        when(tripRepository.findAllByEventId(EVENT_ID)).thenReturn(List.of());
    }

    @Test
    void submit_withReadyContactBackedDriver_createsTripWithoutAUserDriver() {
        when(tripRepository.save(any(TripEntity.class))).thenAnswer(inv -> inv.getArgument(0));
        SubmitAssignmentsRequest request = new SubmitAssignmentsRequest(
                List.of(new DriverAssignment(DRIVER_PARTICIPANT_ID, List.of(PASSENGER_PARTICIPANT_ID))));

        AssignmentPlanResponse response = service.submit(ORGANIZER_ID, EVENT_ID, request);

        assertEquals(1, response.trips().size());
        TripResponse trip = response.trips().get(0);
        assertNull(trip.driverId());
        assertEquals(DRIVER_PARTICIPANT_ID, trip.driverParticipantId());
        assertEquals("Dell", trip.driverFullName());
        assertEquals(ParticipantStatus.ASSIGNED, contactDriver.getStatus());
        assertEquals(ParticipantStatus.ASSIGNED, passenger.getStatus());
    }

    @Test
    void submit_rejectsDriverWithoutVehicle() {
        contactDriver.setVehicle(null);
        SubmitAssignmentsRequest request = new SubmitAssignmentsRequest(
                List.of(new DriverAssignment(DRIVER_PARTICIPANT_ID, List.of())));

        assertThrows(ConflictException.class, () -> service.submit(ORGANIZER_ID, EVENT_ID, request));
    }

    @Test
    void submit_rejectsDriverNotYetReadyForAssignment() {
        contactDriver.setStatus(ParticipantStatus.REQUESTED);
        SubmitAssignmentsRequest request = new SubmitAssignmentsRequest(
                List.of(new DriverAssignment(DRIVER_PARTICIPANT_ID, List.of())));

        assertThrows(ConflictException.class, () -> service.submit(ORGANIZER_ID, EVENT_ID, request));
    }
}
