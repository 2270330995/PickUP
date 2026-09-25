package com.pickup.event.planning;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.enums.StopStatus;
import com.pickup.common.enums.TripStatus;
import com.pickup.common.geo.GeoPoint;
import com.pickup.common.geo.routing.RouteEstimateService;
import com.pickup.contact.ContactEntity;
import com.pickup.event.EventEntity;
import com.pickup.event.EventRepository;
import com.pickup.event.EventService;
import com.pickup.event.assignment.AssignmentService;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest.DriverAssignment;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripEntity;
import com.pickup.tripstop.TripStopEntity;
import com.pickup.user.UserEntity;
import com.pickup.vehicle.VehicleEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AutoAssignmentServiceTest {

    private static final UUID ORGANIZER_ID = UUID.randomUUID();
    private static final UUID EVENT_ID = UUID.randomUUID();

    @Mock private EventService eventService;
    @Mock private EventRepository eventRepository;
    @Mock private EventParticipantRepository participantRepository;
    @Mock private com.pickup.trip.TripRepository tripRepository;
    @Mock private AssignmentService assignmentService;
    @Mock private EventPlanningStatusWriter planningStatusWriter;
    @Mock private RouteEstimateService routeEstimateService;

    private AutoAssignmentService service;
    private EventEntity event;

    @BeforeEach
    void setUp() {
        service = new AutoAssignmentService(
                eventService, eventRepository, participantRepository, tripRepository,
                assignmentService, planningStatusWriter, routeEstimateService);

        UserEntity organizer = UserEntity.builder().id(ORGANIZER_ID).fullName("Org").email("org@test.com").build();
        event = EventEntity.builder().id(EVENT_ID).organizer(organizer).title("Demo")
                .destinationAddress("Destination").destinationLat(1.0).destinationLng(2.0).build();
        when(eventService.loadOrThrow(EVENT_ID)).thenReturn(event);
        when(routeEstimateService.distanceMeters(any(GeoPoint.class), any(GeoPoint.class))).thenReturn(100.0);
        when(assignmentService.submit(eq(ORGANIZER_ID), eq(EVENT_ID), any()))
                .thenReturn(new AssignmentPlanResponse(EVENT_ID, List.of(), List.of()));
    }

    private EventParticipantEntity driver(ContactEntity contact, VehicleEntity vehicle) {
        return EventParticipantEntity.builder()
                .id(UUID.randomUUID()).event(event).contact(contact)
                .role(ParticipantRole.DRIVER).status(ParticipantStatus.READY).vehicle(vehicle)
                // DriverPassengerScorer skips any driver with no known trip-start location.
                .pickupAddress("Driver start").pickupLat(1.0).pickupLng(2.0)
                .build();
    }

    private EventParticipantEntity passenger(ContactEntity contact, double lat, double lng) {
        return EventParticipantEntity.builder()
                .id(UUID.randomUUID()).event(event).contact(contact)
                .role(ParticipantRole.PASSENGER).status(ParticipantStatus.READY)
                .pickupAddress("Pickup").pickupLat(lat).pickupLng(lng).build();
    }

    @Test
    void generate_leavesAlreadyAssignedTripUntouched_andOnlyMatchesRemainingParticipants() {
        ContactEntity contact = ContactEntity.builder().id(UUID.randomUUID()).name("Contact").build();
        VehicleEntity existingVehicle = VehicleEntity.builder().id(UUID.randomUUID())
                .contact(contact).make("Honda").model("Civic").seats(4).build();
        VehicleEntity newVehicle = VehicleEntity.builder().id(UUID.randomUUID())
                .contact(contact).make("Toyota").model("Corolla").seats(4).build();

        EventParticipantEntity existingDriver = driver(contact, existingVehicle);
        EventParticipantEntity existingPassenger = passenger(contact, 1.1, 2.1);
        EventParticipantEntity newDriver = driver(contact, newVehicle);
        EventParticipantEntity newPassenger = passenger(contact, 1.2, 2.2);

        TripStopEntity existingStop = TripStopEntity.builder()
                .id(UUID.randomUUID()).participant(existingPassenger).sequence(0)
                .address("Pickup").lat(1.1).lng(2.1).status(StopStatus.PENDING).build();
        TripEntity existingTrip = TripEntity.builder()
                .id(UUID.randomUUID()).event(event).driverParticipant(existingDriver).vehicle(existingVehicle)
                .status(TripStatus.ASSIGNED)
                .finalDestinationAddress("Destination").finalDestinationLat(1.0).finalDestinationLng(2.0)
                .stops(new java.util.ArrayList<>(List.of(existingStop)))
                .build();

        when(participantRepository.findAllByEventIdOrderByCreatedAtAsc(EVENT_ID))
                .thenReturn(List.of(existingDriver, existingPassenger, newDriver, newPassenger));
        when(tripRepository.findAllByEventId(EVENT_ID)).thenReturn(List.of(existingTrip));

        service.generate(ORGANIZER_ID, EVENT_ID);

        ArgumentCaptor<SubmitAssignmentsRequest> captor =
                ArgumentCaptor.forClass(SubmitAssignmentsRequest.class);
        org.mockito.Mockito.verify(assignmentService).submit(eq(ORGANIZER_ID), eq(EVENT_ID), captor.capture());
        List<DriverAssignment> assignments = captor.getValue().assignments();

        assertEquals(2, assignments.size());

        DriverAssignment existingAssignment = assignments.stream()
                .filter(a -> a.driverParticipantId().equals(existingDriver.getId()))
                .findFirst().orElseThrow();
        assertEquals(List.of(existingPassenger.getId()), existingAssignment.passengerParticipantIds());

        DriverAssignment newAssignment = assignments.stream()
                .filter(a -> a.driverParticipantId().equals(newDriver.getId()))
                .findFirst().orElseThrow();
        assertTrue(newAssignment.passengerParticipantIds().contains(newPassenger.getId()));
        // The already-assigned passenger must not have been pulled into the new match.
        assertTrue(!newAssignment.passengerParticipantIds().contains(existingPassenger.getId()));
    }

    @Test
    void generate_withNoExistingTrips_matchesAllEligibleParticipants() {
        ContactEntity contact = ContactEntity.builder().id(UUID.randomUUID()).name("Contact").build();
        VehicleEntity vehicle = VehicleEntity.builder().id(UUID.randomUUID())
                .contact(contact).make("Honda").model("Civic").seats(4).build();
        EventParticipantEntity onlyDriver = driver(contact, vehicle);
        EventParticipantEntity onlyPassenger = passenger(contact, 1.1, 2.1);

        when(participantRepository.findAllByEventIdOrderByCreatedAtAsc(EVENT_ID))
                .thenReturn(List.of(onlyDriver, onlyPassenger));
        when(tripRepository.findAllByEventId(EVENT_ID)).thenReturn(List.of());

        service.generate(ORGANIZER_ID, EVENT_ID);

        ArgumentCaptor<SubmitAssignmentsRequest> captor =
                ArgumentCaptor.forClass(SubmitAssignmentsRequest.class);
        org.mockito.Mockito.verify(assignmentService).submit(eq(ORGANIZER_ID), eq(EVENT_ID), captor.capture());
        List<DriverAssignment> assignments = captor.getValue().assignments();

        assertEquals(1, assignments.size());
        assertEquals(onlyDriver.getId(), assignments.get(0).driverParticipantId());
        assertEquals(List.of(onlyPassenger.getId()), assignments.get(0).passengerParticipantIds());
    }
}
