import '../../event/data/event_dtos.dart';

class EventDashboardSummary {
  const EventDashboardSummary({
    required this.eventId,
    required this.title,
    required this.eventTime,
    required this.status,
    required this.statusRaw,
    required this.totalParticipants,
    required this.confirmedDrivers,
    required this.pendingRequests,
    required this.seatsNeeded,
  });

  final String eventId;
  final String title;
  final DateTime eventTime;
  final EventStatus status;
  final String statusRaw;
  final int totalParticipants;
  final int confirmedDrivers;
  final int pendingRequests;
  final int seatsNeeded;

  factory EventDashboardSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'UNKNOWN';
    return EventDashboardSummary(
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      eventTime: DateTime.parse(json['eventTime'] as String),
      status: eventStatusFromString(raw),
      statusRaw: raw,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
      confirmedDrivers: (json['confirmedDrivers'] as num?)?.toInt() ?? 0,
      pendingRequests: (json['pendingRequests'] as num?)?.toInt() ?? 0,
      seatsNeeded: (json['seatsNeeded'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrganizerDashboardResponse {
  const OrganizerDashboardResponse({
    required this.totalEvents,
    required this.activeEvents,
    required this.events,
  });

  final int totalEvents;
  final int activeEvents;
  final List<EventDashboardSummary> events;

  factory OrganizerDashboardResponse.fromJson(Map<String, dynamic> json) {
    final events = (json['events'] as List?) ?? const [];
    return OrganizerDashboardResponse(
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      activeEvents: (json['activeEvents'] as num?)?.toInt() ?? 0,
      events: events
          .whereType<Map<String, dynamic>>()
          .map(EventDashboardSummary.fromJson)
          .toList(growable: false),
    );
  }
}

class EventDashboardTotals {
  const EventDashboardTotals({
    required this.totalParticipants,
    required this.organizers,
    required this.confirmedDrivers,
    required this.passengersNeedingRides,
    required this.independentAttendees,
    required this.pendingRequests,
  });

  final int totalParticipants;
  final int organizers;
  final int confirmedDrivers;
  final int passengersNeedingRides;
  final int independentAttendees;
  final int pendingRequests;

  factory EventDashboardTotals.fromJson(Map<String, dynamic> json) {
    return EventDashboardTotals(
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
      organizers: (json['organizers'] as num?)?.toInt() ?? 0,
      confirmedDrivers: (json['confirmedDrivers'] as num?)?.toInt() ?? 0,
      passengersNeedingRides:
          (json['passengersNeedingRides'] as num?)?.toInt() ?? 0,
      independentAttendees:
          (json['independentAttendees'] as num?)?.toInt() ?? 0,
      pendingRequests: (json['pendingRequests'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventDashboardSeats {
  const EventDashboardSeats({
    required this.totalSeatsAvailable,
    required this.seatsNeeded,
    required this.seatsSurplus,
    required this.driversMissingVehicle,
  });

  final int totalSeatsAvailable;
  final int seatsNeeded;
  final int seatsSurplus;
  final int driversMissingVehicle;

  factory EventDashboardSeats.fromJson(Map<String, dynamic> json) {
    return EventDashboardSeats(
      totalSeatsAvailable: (json['totalSeatsAvailable'] as num?)?.toInt() ?? 0,
      seatsNeeded: (json['seatsNeeded'] as num?)?.toInt() ?? 0,
      seatsSurplus: (json['seatsSurplus'] as num?)?.toInt() ?? 0,
      driversMissingVehicle:
          (json['driversMissingVehicle'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventDashboardResponse {
  const EventDashboardResponse({
    required this.eventId,
    required this.title,
    required this.eventTime,
    required this.status,
    required this.statusRaw,
    required this.planningStatus,
    required this.totals,
    required this.seats,
  });

  final String eventId;
  final String title;
  final DateTime eventTime;
  final EventStatus status;
  final String statusRaw;
  final String planningStatus;
  final EventDashboardTotals totals;
  final EventDashboardSeats seats;

  factory EventDashboardResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'UNKNOWN';
    return EventDashboardResponse(
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      eventTime: DateTime.parse(json['eventTime'] as String),
      status: eventStatusFromString(raw),
      statusRaw: raw,
      planningStatus: json['planningStatus'] as String? ?? 'NOT_STARTED',
      totals: EventDashboardTotals.fromJson(
          json['totals'] as Map<String, dynamic>),
      seats: EventDashboardSeats.fromJson(
          json['seats'] as Map<String, dynamic>),
    );
  }
}
