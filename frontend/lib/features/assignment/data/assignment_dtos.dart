import '../../trip/data/trip_dtos.dart';

class DriverAssignmentInput {
  const DriverAssignmentInput({
    required this.driverParticipantId,
    required this.passengerParticipantIds,
    this.overrideCapacity = false,
  });

  final String driverParticipantId;
  final List<String> passengerParticipantIds;

  /// Organizer explicitly confirmed overloading this driver beyond
  /// `seats - 1` passengers (via the "Overload" warning in the passenger
  /// picker). The backend rejects an over-capacity list unless this is true.
  final bool overrideCapacity;

  Map<String, dynamic> toJson() => {
        'driverParticipantId': driverParticipantId,
        'passengerParticipantIds': passengerParticipantIds,
        'overrideCapacity': overrideCapacity,
      };
}

class SubmitAssignmentsRequest {
  const SubmitAssignmentsRequest({required this.assignments});

  final List<DriverAssignmentInput> assignments;

  Map<String, dynamic> toJson() => {
        'assignments': assignments.map((a) => a.toJson()).toList(),
      };
}

class AssignmentPlanResponse {
  const AssignmentPlanResponse({
    required this.eventId,
    required this.trips,
    required this.unassignedConfirmedPassengerIds,
  });

  final String eventId;
  final List<TripResponse> trips;
  final List<String> unassignedConfirmedPassengerIds;

  factory AssignmentPlanResponse.fromJson(Map<String, dynamic> json) {
    final trips = (json['trips'] as List?) ?? const [];
    final unassigned = (json['unassignedConfirmedPassengerIds'] as List?) ?? const [];
    return AssignmentPlanResponse(
      eventId: json['eventId'] as String,
      trips: trips
          .whereType<Map<String, dynamic>>()
          .map(TripResponse.fromJson)
          .toList(growable: false),
      unassignedConfirmedPassengerIds:
          unassigned.whereType<String>().toList(growable: false),
    );
  }

  int get assignedTripCount =>
      trips.where((t) => t.status == TripStatus.assigned).length;

  int get assignedPassengerCount => trips
      .where((t) => t.status == TripStatus.assigned)
      .fold<int>(0, (sum, t) => sum + t.stops.length);

  String get summaryMessage =>
      'Created $assignedTripCount trips · '
      '$assignedPassengerCount passengers assigned · '
      '${unassignedConfirmedPassengerIds.length} unassigned';

  String get autoAssignSummaryMessage =>
      '$summaryMessage · Stop order optimized';
}
