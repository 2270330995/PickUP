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
        // lenient: not every test has new (unlocked) drivers/passengers left to score,
        // so this stub goes unused in those cases — that's expected, not a test bug.
        org.mockito.Mockito.lenient()
                .when(routeEstimateService.distanceMeters(any(GeoPoint.class), any(GeoPoint.class)))
                .thenReturn(100.0);
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

    @Test
    void generate_driverWithAnEmptyAssignedTrip_isStillMatchedWithNewPassengers() {
        // Regression test: a driver can already have an ASSIGNED trip with zero
        // stops (e.g. created by an earlier auto-assign run, or a manual save with
        // nobody picked). That empty shell has nothing worth preserving, so the
        // driver must remain eligible rather than being locked out of every future
        // auto-assign run.
        ContactEntity contact = ContactEntity.builder().id(UUID.randomUUID()).name("Contact").build();
        VehicleEntity vehicle = VehicleEntity.builder().id(UUID.randomUUID())
                .contact(contact).make("Honda").model("Civic").seats(4).build();
        EventParticipantEntity emptyTripDriver = driver(contact, vehicle);
        EventParticipantEntity waitingPassenger = passenger(contact, 1.1, 2.1);

        TripEntity emptyTrip = TripEntity.builder()
                .id(UUID.randomUUID()).event(event).driverParticipant(emptyTripDriver).vehicle(vehicle)
                .status(TripStatus.ASSIGNED)
                .finalDestinationAddress("Destination").finalDestinationLat(1.0).finalDestinationLng(2.0)
                .stops(new java.util.ArrayList<>())
                .build();

        when(participantRepository.findAllByEventIdOrderByCreatedAtAsc(EVENT_ID))
                .thenReturn(List.of(emptyTripDriver, waitingPassenger));
        when(tripRepository.findAllByEventId(EVENT_ID)).thenReturn(List.of(emptyTrip));

        service.generate(ORGANIZER_ID, EVENT_ID);

        ArgumentCaptor<SubmitAssignmentsRequest> captor =
                ArgumentCaptor.forClass(SubmitAssignmentsRequest.class);
        org.mockito.Mockito.verify(assignmentService).submit(eq(ORGANIZER_ID), eq(EVENT_ID), captor.capture());
        List<DriverAssignment> assignments = captor.getValue().assignments();

        assertEquals(1, assignments.size());
        assertEquals(emptyTripDriver.getId(), assignments.get(0).driverParticipantId());
        assertEquals(List.of(waitingPassenger.getId()), assignments.get(0).passengerParticipantIds());
    }

    @Test
    void generate_driverWithAPreviouslyConfirmedOverload_carriesItForwardWithOverrideCapacityTrue() {
        // Regression test: an already-saved overloaded trip (more passengers than
        // seats - 1, confirmed earlier via the organizer's "Overload" override) must
        // be re-declared with overrideCapacity=true when carried forward unchanged —
        // otherwise AssignmentService.submit()'s capacity check rejects it on every
        // subsequent auto-assign run, even though nothing about it actually changed.
        ContactEntity contact = ContactEntity.builder().id(UUID.randomUUID()).name("Contact").build();
        // 2-seat vehicle allows only 1 passenger; this trip already has 2.
        VehicleEntity vehicle = VehicleEntity.builder().id(UUID.randomUUID())
                .contact(contact).make("Honda").model("Civic").seats(2).build();
        EventParticipantEntity overloadedDriver = driver(contact, vehicle);
        EventParticipantEntity passenger1 = passenger(contact, 1.1, 2.1);
        EventParticipantEntity passenger2 = passenger(contact, 1.2, 2.2);

        TripStopEntity stop1 = TripStopEntity.builder()
                .id(UUID.randomUUID()).participant(passenger1).sequence(0)
                .address("Pickup 1").lat(1.1).lng(2.1).status(StopStatus.PENDING).build();
        TripStopEntity stop2 = TripStopEntity.builder()
                .id(UUID.randomUUID()).participant(passenger2).sequence(1)
                .address("Pickup 2").lat(1.2).lng(2.2).status(StopStatus.PENDING).build();
        TripEntity overloadedTrip = TripEntity.builder()
                .id(UUID.randomUUID()).event(event).driverParticipant(overloadedDriver).vehicle(vehicle)
                .status(TripStatus.ASSIGNED)
                .finalDestinationAddress("Destination").finalDestinationLat(1.0).finalDestinationLng(2.0)
                .stops(new java.util.ArrayList<>(List.of(stop1, stop2)))
                .build();

        when(participantRepository.findAllByEventIdOrderByCreatedAtAsc(EVENT_ID))
                .thenReturn(List.of(overloadedDriver, passenger1, passenger2));
        when(tripRepository.findAllByEventId(EVENT_ID)).thenReturn(List.of(overloadedTrip));

        service.generate(ORGANIZER_ID, EVENT_ID);

        ArgumentCaptor<SubmitAssignmentsRequest> captor =
                ArgumentCaptor.forClass(SubmitAssignmentsRequest.class);
        org.mockito.Mockito.verify(assignmentService).submit(eq(ORGANIZER_ID), eq(EVENT_ID), captor.capture());
        List<DriverAssignment> assignments = captor.getValue().assignments();

        assertEquals(1, assignments.size());
        DriverAssignment carriedForward = assignments.get(0);
        assertEquals(overloadedDriver.getId(), carriedForward.driverParticipantId());
        assertEquals(List.of(passenger1.getId(), passenger2.getId()), carriedForward.passengerParticipantIds());
        assertTrue(carriedForward.overrideCapacity());
    }
}
