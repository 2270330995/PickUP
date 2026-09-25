import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickup/features/assignment/data/assignment_api.dart';
import 'package:pickup/features/assignment/data/assignment_dtos.dart';
import 'package:pickup/features/assignment/presentation/manage_assignments_screen.dart';
import 'package:pickup/features/event/data/event_api.dart';
import 'package:pickup/features/event/data/event_dtos.dart';
import 'package:pickup/features/participant/data/participant_api.dart';
import 'package:pickup/features/participant/data/participant_dtos.dart';
import 'package:pickup/features/trip/data/trip_dtos.dart';

const _eventId = 'e1';

class _FakeAssignmentApi extends AssignmentApi {
  _FakeAssignmentApi() : super(Dio());

  SubmitAssignmentsRequest? lastRequest;

  @override
  Future<AssignmentPlanResponse> submit(
    String eventId,
    SubmitAssignmentsRequest req,
  ) async {
    lastRequest = req;
    return const AssignmentPlanResponse(
      eventId: _eventId,
      trips: [],
      unassignedConfirmedPassengerIds: [],
    );
  }
}

EventResponse _event() => EventResponse(
      id: _eventId,
      organizerId: 'org1',
      organizerName: 'Org',
      title: 'Demo Event',
      destinationAddress: 'Destination Ave',
      destinationLat: 1,
      destinationLng: 1,
      eventTime: DateTime(2026, 1, 1),
      status: EventStatus.open,
      statusRaw: 'OPEN',
      planningStatus: 'NOT_STARTED',
      assignmentGenerated: false,
      participantCount: 3,
      createdAt: DateTime(2026, 1, 1),
    );

// A 2-seat vehicle allows only 1 passenger (seats - 1).
EventParticipantResponse _driver({int seats = 2}) => EventParticipantResponse(
      id: 'driver1',
      eventId: _eventId,
      contactId: 'contact-driver1',
      displayName: 'Dana Driver',
      userFullName: '',
      userEmail: '',
      role: ParticipantRole.driver,
      roleRaw: 'DRIVER',
      status: ParticipantStatus.ready,
      statusRaw: 'READY',
      vehicleId: 'veh1',
      vehicleSummary: ParticipantVehicleSummary(id: 'veh1', seats: seats),
      createdAt: DateTime(2026, 1, 1),
    );

EventParticipantResponse _passenger(String id, String name) =>
    EventParticipantResponse(
      id: id,
      eventId: _eventId,
      contactId: 'contact-$id',
      displayName: name,
      userFullName: '',
      userEmail: '',
      role: ParticipantRole.passenger,
      roleRaw: 'PASSENGER',
      status: ParticipantStatus.ready,
      statusRaw: 'READY',
      pickupAddress: '123 Main St',
      pickupLat: 1,
      pickupLng: 1,
      createdAt: DateTime(2026, 1, 1),
    );

TripResponse _trip({
  required String driverParticipantId,
  required int seats,
  required List<TripStopSummary> stops,
}) =>
    TripResponse(
      id: 'trip-$driverParticipantId',
      eventId: _eventId,
      eventTitle: 'Demo Event',
      eventTime: DateTime(2026, 1, 1),
      driverFullName: 'Driver',
      driverParticipantId: driverParticipantId,
      vehicleId: 'veh1',
      vehicleSummary: TripVehicleSummary(id: 'veh1', seats: seats),
      status: TripStatus.assigned,
      statusRaw: 'ASSIGNED',
      finalDestinationAddress: 'Destination Ave',
      finalDestinationLat: 1,
      finalDestinationLng: 1,
      stops: stops,
      navigationTargetType: NavigationTargetType.none,
      navigationTargetTypeRaw: 'NONE',
    );

TripStopSummary _stop({required String id, required String participantId, required String name}) =>
    TripStopSummary(
      id: id,
      sequence: 0,
      participantId: participantId,
      userFullName: name,
      address: '123 Main St',
      lat: 1,
      lng: 1,
      status: StopStatus.pending,
      statusRaw: 'PENDING',
    );

Future<_FakeAssignmentApi> _pumpScreen(
  WidgetTester tester, {
  required List<EventParticipantResponse> participants,
  List<TripResponse> trips = const [],
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fakeApi = _FakeAssignmentApi();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventDetailProvider.overrideWith((ref, id) async => _event()),
        eventParticipantsProvider.overrideWith((ref, id) async => participants),
        eventAssignmentPlanProvider.overrideWith(
          (ref, id) async => AssignmentPlanResponse(
            eventId: _eventId,
            trips: trips,
            unassignedConfirmedPassengerIds: const [],
          ),
        ),
        assignmentApiProvider.overrideWithValue(fakeApi),
      ],
      child: const MaterialApp(
        home: ManageAssignmentsScreen(eventId: _eventId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeApi;
}

Future<void> _openPicker(WidgetTester tester) async {
  // The screen's AppBar title is also "Assign passengers", so scope to the
  // FilledButton to avoid an ambiguous match.
  await tester.tap(find.widgetWithText(FilledButton, 'Assign passengers'));
  await tester.pumpAndSettle();
}

/// The passenger's name also appears in the "Unassigned passengers" list on
/// the main screen behind the sheet, so taps must be scoped to the picker's
/// own CheckboxListTile rows to avoid an ambiguous match.
Future<void> _togglePassenger(WidgetTester tester, String name) async {
  await tester.tap(find.widgetWithText(CheckboxListTile, name));
  await tester.pumpAndSettle();
}

Future<void> _openPickerAndSelectBoth(WidgetTester tester) async {
  await _openPicker(tester);
  await _togglePassenger(tester, 'Passenger One');
  await _togglePassenger(tester, 'Passenger Two');
}

void main() {
  group('ManageAssignmentsScreen — overload flow', () {
    testWidgets(
        'selecting within capacity keeps the button labeled Done and closes without a dialog',
        (tester) async {
      await _pumpScreen(tester, participants: [
        _driver(seats: 2),
        _passenger('p1', 'Passenger One'),
        _passenger('p2', 'Passenger Two'),
      ]);

      await _openPicker(tester);
      await _togglePassenger(tester, 'Passenger One');

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Overload'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('1/1 seats'), findsOneWidget);
    });

    testWidgets(
        'selecting more passengers than seats allow is not blocked, and relabels the button Overload',
        (tester) async {
      await _pumpScreen(tester, participants: [
        _driver(seats: 2),
        _passenger('p1', 'Passenger One'),
        _passenger('p2', 'Passenger Two'),
      ]);

      await _openPickerAndSelectBoth(tester);

      // The old hard cap used to show a "Vehicle full" SnackBar and refuse
      // the second selection; both checkboxes must now be checked instead.
      expect(find.text('Vehicle full: max 1 passengers'), findsNothing);
      final checkboxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checkboxes.every((c) => c.value == true), isTrue);
      expect(find.textContaining('over capacity'), findsOneWidget);
      expect(find.text('Overload'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('tapping Overload then Cancel in the warning dialog keeps the sheet open',
        (tester) async {
      await _pumpScreen(tester, participants: [
        _driver(seats: 2),
        _passenger('p1', 'Passenger One'),
        _passenger('p2', 'Passenger Two'),
      ]);

      await _openPickerAndSelectBoth(tester);
      await tester.tap(find.text('Overload'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // Still on the picker sheet, selection untouched.
      expect(find.textContaining('Assign to'), findsOneWidget);
      expect(find.text('Overload'), findsOneWidget);
    });

    testWidgets(
        'confirming Overload closes the sheet, reflects on the driver card, and saves with overrideCapacity true',
        (tester) async {
      final fakeApi = await _pumpScreen(tester, participants: [
        _driver(seats: 2),
        _passenger('p1', 'Passenger One'),
        _passenger('p2', 'Passenger Two'),
      ]);

      await _openPickerAndSelectBoth(tester);
      await tester.tap(find.text('Overload'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Overload')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Assign to'), findsNothing);
      expect(find.text('2/1 seats'), findsOneWidget);

      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();

      expect(fakeApi.lastRequest, isNotNull);
      final assignment = fakeApi.lastRequest!.assignments.single;
      expect(assignment.driverParticipantId, 'driver1');
      expect(assignment.passengerParticipantIds, containsAll(['p1', 'p2']));
      expect(assignment.overrideCapacity, isTrue);
    });
  });

  group('ManageAssignmentsScreen — cancel button', () {
    testWidgets('there is no Auto assign button, only Cancel and Save plan', (tester) async {
      await _pumpScreen(tester, participants: [_driver(seats: 3)]);

      expect(find.text('Auto assign'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save plan'), findsOneWidget);
    });

    testWidgets(
        'Cancel discards an unsaved passenger pick and reverts to the last saved plan',
        (tester) async {
      final passengerOne = _passenger('p1', 'Passenger One');
      final passengerTwo = _passenger('p2', 'Passenger Two');
      await _pumpScreen(
        tester,
        participants: [_driver(seats: 3), passengerOne, passengerTwo],
        trips: [
          _trip(
            driverParticipantId: 'driver1',
            seats: 3,
            stops: [_stop(id: 's1', participantId: 'p1', name: 'Passenger One')],
          ),
        ],
      );

      expect(find.text('1/2 seats'), findsOneWidget);

      await _openPicker(tester);
      await _togglePassenger(tester, 'Passenger Two');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('2/2 seats'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('1/2 seats'), findsOneWidget);
    });
  });
}
