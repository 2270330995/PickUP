import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pickup/features/dashboard/data/dashboard_api.dart';
import 'package:pickup/features/dashboard/data/dashboard_dtos.dart';
import 'package:pickup/features/assignment/data/assignment_api.dart';
import 'package:pickup/features/assignment/data/assignment_dtos.dart';
import 'package:pickup/features/event/data/event_api.dart';
import 'package:pickup/features/event/data/event_dtos.dart';
import 'package:pickup/features/event/presentation/event_detail_screen.dart';
import 'package:pickup/features/participant/data/participant_api.dart';
import 'package:pickup/features/participant/data/participant_dtos.dart';
import 'package:pickup/features/user/data/user_api.dart';
import 'package:pickup/features/user/data/user_dtos.dart';

const _eventId = 'e1';
const _organizerId = 'org1';

Map<String, dynamic> _eventJson() => {
      'id': _eventId,
      'organizerId': _organizerId,
      'organizerName': 'Org',
      'title': 'Demo Event',
      'description': null,
      'destinationAddress': 'Oracle Park',
      'destinationLat': 37.7786,
      'destinationLng': -122.3893,
      'eventTime': '2026-02-01T18:00:00.000Z',
      'status': 'OPEN',
      'planningStatus': 'COMPLETED',
      'assignmentGenerated': true,
      'participantCount': 4,
      'currentUserParticipantRole': null,
      'currentUserParticipantStatus': null,
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _userJson() => {
      'id': _organizerId,
      'email': 'org@test.com',
      'fullName': 'Org Organizer',
      'phone': null,
      'systemRoles': ['USER'],
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _vehicleSummaryJson(int seats) => {
      'id': 'veh-$seats',
      'label': 'Car',
      'make': null,
      'model': null,
      'color': null,
      'plate': null,
      'seats': seats,
    };

Map<String, dynamic> _driverJson({
  required String id,
  required String name,
  required String status,
  Map<String, dynamic>? vehicleSummary,
}) =>
    {
      'id': id,
      'eventId': _eventId,
      'userId': null,
      'contactId': 'contact-$id',
      'displayName': name,
      'displayEmail': null,
      'userFullName': '',
      'userEmail': '',
      'role': 'DRIVER',
      'status': status,
      'pickupAddress': null,
      'pickupLat': null,
      'pickupLng': null,
      'vehicleId': vehicleSummary == null ? null : vehicleSummary['id'],
      'vehicleSummary': vehicleSummary,
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _passengerJson({required String id, required String name}) => {
      'id': id,
      'eventId': _eventId,
      'userId': null,
      'contactId': 'contact-$id',
      'displayName': name,
      'displayEmail': null,
      'userFullName': '',
      'userEmail': '',
      'role': 'PASSENGER',
      'status': 'READY',
      'pickupAddress': null,
      'pickupLat': null,
      'pickupLng': null,
      'vehicleId': null,
      'vehicleSummary': null,
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _dashboardJson() => {
      'eventId': _eventId,
      'title': 'Demo Event',
      'eventTime': '2026-02-01T18:00:00.000Z',
      'status': 'OPEN',
      'planningStatus': 'COMPLETED',
      'totals': {
        'totalParticipants': 4,
        'organizers': 1,
        'confirmedDrivers': 2,
        'passengersNeedingRides': 1,
        'independentAttendees': 0,
        'pendingRequests': 0,
      },
      'seats': {
        'totalSeatsAvailable': 7,
        'seatsNeeded': 1,
        'seatsSurplus': 6,
        'driversMissingVehicle': 1,
      },
    };

Map<String, dynamic> _stopJson({required String id, required int sequence, required String status}) => {
      'id': id,
      'sequence': sequence,
      'participantId': 'passenger-$id',
      'userId': null,
      'userFullName': 'Passenger $id',
      'address': '123 Main St',
      'meetingPointName': null,
      'lat': 37.77,
      'lng': -122.42,
      'status': status,
      'etaMinutes': null,
      'actualArrivalTime': null,
      'actualDepartureTime': null,
    };

Map<String, dynamic> _tripJson({
  required String driverParticipantId,
  required int seats,
  required List<Map<String, dynamic>> stops,
}) =>
    {
      'id': 'trip-$driverParticipantId',
      'eventId': _eventId,
      'eventTitle': 'Demo Event',
      'eventTime': '2026-02-01T18:00:00.000Z',
      'driverId': null,
      'driverFullName': 'Driver',
      'driverParticipantId': driverParticipantId,
      'vehicleId': 'veh-$seats',
      'vehicleSummary': _vehicleSummaryJson(seats),
      'status': 'ASSIGNED',
      'currentStopId': null,
      'finalDestinationAddress': 'Oracle Park',
      'finalDestinationLat': 37.7786,
      'finalDestinationLng': -122.3893,
      'startedAt': null,
      'completedAt': null,
      'stops': stops,
      'navigationTargetType': 'NONE',
      'navigationLabel': null,
      'navigationUrl': null,
    };

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<Map<String, dynamic>> participants,
  required List<Map<String, dynamic>> trips,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/event',
    routes: [
      GoRoute(path: '/event', builder: (_, __) => const EventDetailScreen(eventId: _eventId)),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventDetailProvider.overrideWith((ref, id) async => EventResponse.fromJson(_eventJson())),
        currentUserProvider.overrideWith((ref) async => UserResponse.fromJson(_userJson())),
        eventParticipantsProvider.overrideWith(
          (ref, id) async => participants.map(EventParticipantResponse.fromJson).toList(),
        ),
        eventDashboardProvider.overrideWith(
          (ref, id) async => EventDashboardResponse.fromJson(_dashboardJson()),
        ),
        eventAssignmentPlanProvider.overrideWith(
          (ref, id) async => AssignmentPlanResponse.fromJson({
            'eventId': _eventId,
            'trips': trips,
            'unassignedConfirmedPassengerIds': <String>[],
          }),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EventDetailScreen — driver seat counts', () {
    testWidgets(
        'counts the driver plus active passenger stops, excluding cancelled ones, against vehicle capacity',
        (tester) async {
      await _pumpScreen(
        tester,
        participants: [
          _driverJson(
            id: 'driver-jack',
            name: 'Jack',
            status: 'ASSIGNED',
            vehicleSummary: _vehicleSummaryJson(4),
          ),
        ],
        trips: [
          _tripJson(
            driverParticipantId: 'driver-jack',
            seats: 4,
            stops: [
              _stopJson(id: 's1', sequence: 1, status: 'PICKED_UP'),
              _stopJson(id: 's2', sequence: 2, status: 'ARRIVED'),
              _stopJson(id: 's3', sequence: 3, status: 'CANCELLED'),
            ],
          ),
        ],
      );

      // 2 active passengers + the driver's own seat = 3, out of 4 total.
      expect(find.text('3/4 seats assigned'), findsOneWidget);
    });

    testWidgets('counts just the driver (1 seat) against capacity when there is no trip yet', (tester) async {
      await _pumpScreen(
        tester,
        participants: [
          _driverJson(
            id: 'driver-noassign',
            name: 'Jacob',
            status: 'READY',
            vehicleSummary: _vehicleSummaryJson(3),
          ),
        ],
        trips: const [],
      );

      expect(find.text('1/3 seats assigned'), findsOneWidget);
    });

    testWidgets('shows nothing for a driver without a vehicle', (tester) async {
      await _pumpScreen(
        tester,
        participants: [
          _driverJson(id: 'driver-novehicle', name: 'Noah', status: 'READY', vehicleSummary: null),
        ],
        trips: const [],
      );

      expect(find.textContaining('seats assigned'), findsNothing);
      // The existing "vehicle required" messaging still shows instead.
      expect(find.textContaining('Vehicle required before assignment'), findsOneWidget);
    });

    testWidgets('does not show a seat count on passenger rows', (tester) async {
      await _pumpScreen(
        tester,
        participants: [
          _driverJson(
            id: 'driver-jack',
            name: 'Jack',
            status: 'ASSIGNED',
            vehicleSummary: _vehicleSummaryJson(4),
          ),
          _passengerJson(id: 'passenger-dell', name: 'Dell'),
        ],
        trips: [
          _tripJson(
            driverParticipantId: 'driver-jack',
            seats: 4,
            stops: [_stopJson(id: 's1', sequence: 1, status: 'PICKED_UP')],
          ),
        ],
      );

      // Exactly one seat-count line total — the driver's, not the passenger's.
      // 1 active passenger + the driver's own seat = 2, out of 4 total.
      expect(find.textContaining('seats assigned'), findsOneWidget);
      expect(find.text('2/4 seats assigned'), findsOneWidget);
      expect(find.text('Dell'), findsOneWidget);
    });
  });
}
