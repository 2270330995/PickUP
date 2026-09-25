import 'package:flutter_test/flutter_test.dart';

import 'package:pickup/features/assignment/data/assignment_dtos.dart';
import 'package:pickup/features/event/data/event_dtos.dart';
import 'package:pickup/features/event/presentation/event_map_markers.dart';
import 'package:pickup/features/participant/data/participant_dtos.dart';
import 'package:pickup/features/trip/data/trip_dtos.dart';

EventResponse _event() => EventResponse(
      id: 'e1',
      organizerId: 'org1',
      organizerName: 'Org',
      title: 'Demo Event',
      destinationAddress: 'Destination Ave',
      destinationLat: 37.0,
      destinationLng: -122.0,
      eventTime: DateTime(2026, 1, 1),
      status: EventStatus.open,
      statusRaw: 'OPEN',
      planningStatus: 'COMPLETED',
      assignmentGenerated: true,
      participantCount: 0,
      createdAt: DateTime(2026, 1, 1),
    );

EventParticipantResponse _participant({
  required String id,
  ParticipantRole role = ParticipantRole.passenger,
  ParticipantStatus status = ParticipantStatus.ready,
  double? lat,
  double? lng,
  String? userId,
  String name = 'Name',
}) =>
    EventParticipantResponse(
      id: id,
      eventId: 'e1',
      userId: userId,
      displayName: name,
      userFullName: name,
      userEmail: '',
      role: role,
      roleRaw: participantRoleToString(role),
      status: status,
      statusRaw: '',
      pickupLat: lat,
      pickupLng: lng,
      createdAt: DateTime(2026, 1, 1),
    );

const _vehicle = TripVehicleSummary(id: 'v1', seats: 4);

TripStopSummary _stop({
  required String id,
  required String participantId,
  double lat = 1,
  double lng = 1,
  String name = 'Passenger',
}) =>
    TripStopSummary(
      id: id,
      sequence: 0,
      participantId: participantId,
      userFullName: name,
      address: 'addr',
      lat: lat,
      lng: lng,
      status: StopStatus.pending,
      statusRaw: 'PENDING',
    );

TripResponse _trip({
  required String id,
  String? driverParticipantId,
  String? driverId,
  List<TripStopSummary> stops = const [],
}) =>
    TripResponse(
      id: id,
      eventId: 'e1',
      eventTitle: 'Demo Event',
      eventTime: DateTime(2026, 1, 1),
      driverId: driverId,
      driverFullName: 'Driver',
      driverParticipantId: driverParticipantId,
      vehicleId: 'v1',
      vehicleSummary: _vehicle,
      status: TripStatus.assigned,
      statusRaw: 'ASSIGNED',
      finalDestinationAddress: 'Destination Ave',
      finalDestinationLat: 37.0,
      finalDestinationLng: -122.0,
      stops: stops,
      navigationTargetType: NavigationTargetType.none,
      navigationTargetTypeRaw: 'NONE',
    );

AssignmentPlanResponse _plan({List<TripResponse> trips = const []}) =>
    AssignmentPlanResponse(
      eventId: 'e1',
      trips: trips,
      unassignedConfirmedPassengerIds: const [],
    );

void main() {
  group('buildEventMapMarkers', () {
    test('destination marker is always present, even with zero participants', () {
      final markers = buildEventMapMarkers(
        event: _event(),
        participants: const [],
        plan: _plan(),
      );

      expect(markers, hasLength(1));
      expect(markers.single.kind, EventMapMarkerKind.destination);
      expect(markers.single.lat, 37.0);
      expect(markers.single.lng, -122.0);
    });

    test('empty event (no participants, no trips): result is exactly the destination marker', () {
      final markers = buildEventMapMarkers(
        event: _event(),
        participants: const [],
        plan: _plan(trips: const []),
      );

      expect(markers, hasLength(1));
      expect(markers.single.kind, EventMapMarkerKind.destination);
    });

    test(
        "a trip's driver and all its passengers share colorGroupIndex; a second trip gets a different index",
        () {
      final driver1 = _participant(
          id: 'driver1', role: ParticipantRole.driver, lat: 1, lng: 1);
      final passenger1 = _participant(id: 'p1', lat: 2, lng: 2);
      final driver2 = _participant(
          id: 'driver2', role: ParticipantRole.driver, lat: 3, lng: 3);
      final passenger2 = _participant(id: 'p2', lat: 4, lng: 4);

      final trip1 = _trip(
        id: 't1',
        driverParticipantId: 'driver1',
        stops: [_stop(id: 's1', participantId: 'p1')],
      );
      final trip2 = _trip(
        id: 't2',
        driverParticipantId: 'driver2',
        stops: [_stop(id: 's2', participantId: 'p2')],
      );

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [driver1, passenger1, driver2, passenger2],
        plan: _plan(trips: [trip1, trip2]),
      );

      final trip1Markers =
          markers.where((m) => m.id == 'driver-driver1' || m.id == 'stop-s1');
      final trip2Markers =
          markers.where((m) => m.id == 'driver-driver2' || m.id == 'stop-s2');

      expect(trip1Markers.map((m) => m.colorGroupIndex).toSet(), {0});
      expect(trip2Markers.map((m) => m.colorGroupIndex).toSet(), {1});
    });

    test(
        'a participant not on any trip gets EventMapMarkerKind.unassigned, not grouped with any driver',
        () {
      final passenger = _participant(id: 'p1', lat: 5, lng: 5);

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [passenger],
        plan: _plan(),
      );

      final unassigned =
          markers.singleWhere((m) => m.kind == EventMapMarkerKind.unassigned);
      expect(unassigned.id, 'unassigned-p1');
      expect(unassigned.colorGroupIndex, isNull);
    });

    test(
        'a participant with pickupLat/pickupLng both null is omitted entirely',
        () {
      final noLocation = _participant(id: 'p1');

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [noLocation],
        plan: _plan(),
      );

      expect(markers, hasLength(1));
      expect(markers.single.kind, EventMapMarkerKind.destination);
    });

    test('more drivers/trips than palette colors wrap around via modulo rather than throwing',
        () {
      final paletteSize = eventMapColorPalette.length;
      final extraTrips = paletteSize + 2;

      final participants = <EventParticipantResponse>[];
      final trips = <TripResponse>[];
      for (var i = 0; i < extraTrips; i++) {
        participants.add(_participant(
          id: 'driver$i',
          role: ParticipantRole.driver,
          lat: i.toDouble(),
          lng: i.toDouble(),
        ));
        trips.add(_trip(id: 't$i', driverParticipantId: 'driver$i'));
      }

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: participants,
        plan: _plan(trips: trips),
      );

      final driverMarker = markers.singleWhere((m) => m.id == 'driver-driver$paletteSize');
      expect(driverMarker.colorGroupIndex, paletteSize % eventMapColorPalette.length);
      expect(driverMarker.colorGroupIndex, 0);
    });

    test(
        'a trip whose driver is a legacy self-joined user (driverId set, driverParticipantId null) '
        'still produces a driver marker, matched via driverId', () {
      final legacyDriver = _participant(
        id: 'p-legacy',
        role: ParticipantRole.driver,
        userId: 'user-legacy',
        lat: 6,
        lng: 6,
      );

      final trip = _trip(id: 't1', driverId: 'user-legacy');

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [legacyDriver],
        plan: _plan(trips: [trip]),
      );

      final driverMarker =
          markers.singleWhere((m) => m.kind == EventMapMarkerKind.driver);
      expect(driverMarker.id, 'driver-p-legacy');
      expect(driverMarker.lat, 6);
      expect(driverMarker.lng, 6);
    });

    test(
        'a cancelled/rejected/no-show participant not on any trip is not shown as unassigned',
        () {
      final cancelled = _participant(
        id: 'p1',
        status: ParticipantStatus.cancelled,
        lat: 1,
        lng: 1,
      );
      final rejected = _participant(
        id: 'p2',
        status: ParticipantStatus.rejected,
        lat: 2,
        lng: 2,
      );
      final noShow = _participant(
        id: 'p3',
        status: ParticipantStatus.noShow,
        lat: 3,
        lng: 3,
      );

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [cancelled, rejected, noShow],
        plan: _plan(),
      );

      expect(markers, hasLength(1));
      expect(markers.single.kind, EventMapMarkerKind.destination);
    });

    test(
        'a trip whose driver matches neither driverParticipantId nor driverId against any '
        'participant produces no driver marker but still places its passenger stops', () {
      final passenger = _participant(id: 'p1', lat: 2, lng: 2);
      final trip = _trip(
        id: 't1',
        driverParticipantId: 'missing-driver',
        stops: [_stop(id: 's1', participantId: 'p1')],
      );

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [passenger],
        plan: _plan(trips: [trip]),
      );

      expect(markers.where((m) => m.kind == EventMapMarkerKind.driver), isEmpty);
      final stopMarker =
          markers.singleWhere((m) => m.kind == EventMapMarkerKind.passenger);
      expect(stopMarker.id, 'stop-s1');
      expect(stopMarker.colorGroupIndex, 0);
      // The passenger placed via the trip stop must not also get an
      // unassigned marker.
      expect(markers.where((m) => m.kind == EventMapMarkerKind.unassigned), isEmpty);
    });

    test('a driver/passenger role participant with a pickup location and no trips is unassigned, '
        'but organizer/independent-attendee roles are never plotted as unassigned', () {
      final organizer = _participant(
        id: 'org-p',
        role: ParticipantRole.organizer,
        lat: 1,
        lng: 1,
      );
      final independent = _participant(
        id: 'ind-p',
        role: ParticipantRole.independentAttendee,
        lat: 2,
        lng: 2,
      );
      final driverNoTrip = _participant(
        id: 'drv-p',
        role: ParticipantRole.driver,
        lat: 3,
        lng: 3,
      );

      final markers = buildEventMapMarkers(
        event: _event(),
        participants: [organizer, independent, driverNoTrip],
        plan: _plan(),
      );

      final unassignedIds = markers
          .where((m) => m.kind == EventMapMarkerKind.unassigned)
          .map((m) => m.id)
          .toList();
      expect(unassignedIds, ['unassigned-drv-p']);
    });
  });
}
