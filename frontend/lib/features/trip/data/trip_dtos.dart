enum TripStatus {
  assigned,
  started,
  inProgress,
  waitingForNextStop,
  allPassengersPicked,
  headingToDestination,
  completed,
  interrupted,
  unknown,
}

TripStatus tripStatusFromString(String? raw) {
  switch (raw) {
    case 'ASSIGNED':
      return TripStatus.assigned;
    case 'STARTED':
      return TripStatus.started;
    case 'IN_PROGRESS':
      return TripStatus.inProgress;
    case 'WAITING_FOR_NEXT_STOP':
      return TripStatus.waitingForNextStop;
    case 'ALL_PASSENGERS_PICKED':
      return TripStatus.allPassengersPicked;
    case 'HEADING_TO_DESTINATION':
      return TripStatus.headingToDestination;
    case 'COMPLETED':
      return TripStatus.completed;
    case 'INTERRUPTED':
      return TripStatus.interrupted;
    default:
      return TripStatus.unknown;
  }
}

String tripStatusLabel(TripStatus s) {
  switch (s) {
    case TripStatus.assigned:
      return 'Assigned';
    case TripStatus.started:
      return 'Started';
    case TripStatus.inProgress:
      return 'In progress';
    case TripStatus.waitingForNextStop:
      return 'Waiting for next stop';
    case TripStatus.allPassengersPicked:
      return 'All passengers picked';
    case TripStatus.headingToDestination:
      return 'Heading to destination';
    case TripStatus.completed:
      return 'Completed';
    case TripStatus.interrupted:
      return 'Interrupted';
    case TripStatus.unknown:
      return 'Unknown';
  }
}

enum NavigationTargetType {
  none,
  currentStop,
  finalDestination,
  unknown,
}

NavigationTargetType navigationTargetTypeFromString(String? raw) {
  switch (raw) {
    case 'NONE':
      return NavigationTargetType.none;
    case 'CURRENT_STOP':
      return NavigationTargetType.currentStop;
    case 'FINAL_DESTINATION':
      return NavigationTargetType.finalDestination;
    default:
      return NavigationTargetType.unknown;
  }
}

String navigationTargetLabel(NavigationTargetType t) {
  switch (t) {
    case NavigationTargetType.none:
      return 'No navigation';
    case NavigationTargetType.currentStop:
      return 'Current pickup';
    case NavigationTargetType.finalDestination:
      return 'Final destination';
    case NavigationTargetType.unknown:
      return 'Unknown';
  }
}

enum StopStatus {
  pending,
  active,
  navigating,
  arrived,
  pickedUp,
  cancelled,
  skipped,
  unknown,
}

StopStatus stopStatusFromString(String? raw) {
  switch (raw) {
    case 'PENDING':
      return StopStatus.pending;
    case 'ACTIVE':
      return StopStatus.active;
    case 'NAVIGATING':
      return StopStatus.navigating;
    case 'ARRIVED':
      return StopStatus.arrived;
    case 'PICKED_UP':
      return StopStatus.pickedUp;
    case 'CANCELLED':
      return StopStatus.cancelled;
    case 'SKIPPED':
      return StopStatus.skipped;
    default:
      return StopStatus.unknown;
  }
}

String stopStatusLabel(StopStatus s) {
  switch (s) {
    case StopStatus.pending:
      return 'Pending';
    case StopStatus.active:
      return 'Active';
    case StopStatus.navigating:
      return 'Navigating';
    case StopStatus.arrived:
      return 'Arrived';
    case StopStatus.pickedUp:
      return 'Picked up';
    case StopStatus.cancelled:
      return 'Cancelled';
    case StopStatus.skipped:
      return 'Skipped';
    case StopStatus.unknown:
      return 'Unknown';
  }
}

class TripVehicleSummary {
  const TripVehicleSummary({
    required this.id,
    required this.make,
    required this.model,
    this.color,
    this.plate,
    required this.seats,
  });

  final String id;
  final String make;
  final String model;
  final String? color;
  final String? plate;
  final int seats;

  String get label {
    final base = '$make $model';
    final extras = [
      if (color != null && color!.isNotEmpty) color!,
      if (plate != null && plate!.isNotEmpty) plate!,
    ];
    return extras.isEmpty ? base : '$base · ${extras.join(' · ')}';
  }

  factory TripVehicleSummary.fromJson(Map<String, dynamic> json) {
    return TripVehicleSummary(
      id: json['id'] as String,
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String?,
      plate: json['plate'] as String?,
      seats: (json['seats'] as num?)?.toInt() ?? 0,
    );
  }
}

class TripStopSummary {
  const TripStopSummary({
    required this.id,
    required this.sequence,
    required this.participantId,
    this.userId,
    required this.userFullName,
    required this.address,
    this.meetingPointName,
    required this.lat,
    required this.lng,
    required this.status,
    required this.statusRaw,
    this.etaMinutes,
    this.actualArrivalTime,
    this.actualDepartureTime,
  });

  final String id;
  final int sequence;
  final String participantId;
  /// Set for legacy self-joined passengers; null for Contact-backed rows
  /// (use [userFullName], which holds the display name regardless of origin).
  final String? userId;
  final String userFullName;
  final String address;
  final String? meetingPointName;
  final double lat;
  final double lng;
  final StopStatus status;
  final String statusRaw;
  final int? etaMinutes;

  /// Approximate arrival / departure stamps recorded by the driver action.
  final DateTime? actualArrivalTime;
  final DateTime? actualDepartureTime;

  factory TripStopSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'UNKNOWN';
    return TripStopSummary(
      id: json['id'] as String,
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      participantId: json['participantId'] as String,
      userId: json['userId'] as String?,
      userFullName: json['userFullName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      meetingPointName: json['meetingPointName'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      status: stopStatusFromString(raw),
      statusRaw: raw,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      actualArrivalTime: json['actualArrivalTime'] != null
          ? DateTime.parse(json['actualArrivalTime'] as String)
          : null,
      actualDepartureTime: json['actualDepartureTime'] != null
          ? DateTime.parse(json['actualDepartureTime'] as String)
          : null,
    );
  }
}

class TripResponse {
  const TripResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventTime,
    this.driverId,
    required this.driverFullName,
    this.driverParticipantId,
    required this.vehicleId,
    required this.vehicleSummary,
    required this.status,
    required this.statusRaw,
    this.currentStopId,
    required this.finalDestinationAddress,
    required this.finalDestinationLat,
    required this.finalDestinationLng,
    this.startedAt,
    this.completedAt,
    required this.stops,
    required this.navigationTargetType,
    required this.navigationTargetTypeRaw,
    this.navigationLabel,
    this.navigationUrl,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime eventTime;
  /// Set for legacy trips whose driver is a registered user; null for
  /// Contact-backed drivers (use [driverParticipantId] to match those instead).
  final String? driverId;
  final String driverFullName;
  final String? driverParticipantId;
  final String vehicleId;
  final TripVehicleSummary vehicleSummary;
  final TripStatus status;
  final String statusRaw;
  final String? currentStopId;
  final String finalDestinationAddress;
  final double finalDestinationLat;
  final double finalDestinationLng;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<TripStopSummary> stops;
  final NavigationTargetType navigationTargetType;
  final String navigationTargetTypeRaw;
  final String? navigationLabel;
  final String? navigationUrl;

  bool get hasNavigation =>
      navigationUrl != null &&
      navigationUrl!.isNotEmpty &&
      navigationTargetType != NavigationTargetType.none;

  /// Address for the current navigation target, shown separately from [navigationLabel].
  String? navigationAddress(TripStopSummary? currentStop) {
    return switch (navigationTargetType) {
      NavigationTargetType.currentStop => currentStop?.address,
      NavigationTargetType.finalDestination => finalDestinationAddress,
      _ => null,
    };
  }

  factory TripResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'UNKNOWN';
    final navRaw = json['navigationTargetType'] as String? ?? 'NONE';
    final stopsRaw = (json['stops'] as List?) ?? const [];
    return TripResponse(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String? ?? '',
      eventTime: DateTime.parse(json['eventTime'] as String),
      driverId: json['driverId'] as String?,
      driverFullName: json['driverFullName'] as String? ?? '',
      driverParticipantId: json['driverParticipantId'] as String?,
      vehicleId: json['vehicleId'] as String,
      vehicleSummary:
          TripVehicleSummary.fromJson(json['vehicleSummary'] as Map<String, dynamic>),
      status: tripStatusFromString(raw),
      statusRaw: raw,
      currentStopId: json['currentStopId'] as String?,
      finalDestinationAddress: json['finalDestinationAddress'] as String? ?? '',
      finalDestinationLat: (json['finalDestinationLat'] as num?)?.toDouble() ?? 0,
      finalDestinationLng: (json['finalDestinationLng'] as num?)?.toDouble() ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      stops: stopsRaw
          .whereType<Map<String, dynamic>>()
          .map(TripStopSummary.fromJson)
          .toList(growable: false),
      navigationTargetType: navigationTargetTypeFromString(navRaw),
      navigationTargetTypeRaw: navRaw,
      navigationLabel: json['navigationLabel'] as String?,
      navigationUrl: json['navigationUrl'] as String?,
    );
  }
}
