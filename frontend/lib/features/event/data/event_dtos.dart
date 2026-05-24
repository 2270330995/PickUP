import '../../participant/data/participant_dtos.dart';

enum EventStatus { draft, open, closed, inProgress, completed, cancelled, unknown }

EventStatus eventStatusFromString(String? raw) {
  switch (raw) {
    case 'DRAFT':
      return EventStatus.draft;
    case 'OPEN':
      return EventStatus.open;
    case 'CLOSED':
      return EventStatus.closed;
    case 'IN_PROGRESS':
      return EventStatus.inProgress;
    case 'COMPLETED':
      return EventStatus.completed;
    case 'CANCELLED':
      return EventStatus.cancelled;
    default:
      return EventStatus.unknown;
  }
}

String eventStatusLabel(EventStatus s) {
  switch (s) {
    case EventStatus.draft:
      return 'Draft';
    case EventStatus.open:
      return 'Open';
    case EventStatus.closed:
      return 'Closed';
    case EventStatus.inProgress:
      return 'In progress';
    case EventStatus.completed:
      return 'Completed';
    case EventStatus.cancelled:
      return 'Cancelled';
    case EventStatus.unknown:
      return 'Unknown';
  }
}

class EventResponse {
  const EventResponse({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.title,
    this.description,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.eventTime,
    required this.status,
    required this.statusRaw,
    required this.planningStatus,
    required this.assignmentGenerated,
    required this.participantCount,
    this.currentUserParticipantRole,
    this.currentUserParticipantStatus,
    required this.createdAt,
  });

  final String id;
  final String organizerId;
  final String organizerName;
  final String title;
  final String? description;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final DateTime eventTime;
  final EventStatus status;
  final String statusRaw;
  final String planningStatus;
  final bool assignmentGenerated;
  final int participantCount;
  // The current viewer's participant role/status for this event when known.
  // Null when the viewer is not a participant or the endpoint doesn't include it.
  final ParticipantRole? currentUserParticipantRole;
  final ParticipantStatus? currentUserParticipantStatus;
  final DateTime createdAt;

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'UNKNOWN';
    final viewerRoleRaw = json['currentUserParticipantRole'] as String?;
    final viewerStatusRaw = json['currentUserParticipantStatus'] as String?;
    return EventResponse(
      id: json['id'] as String,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      destinationAddress: json['destinationAddress'] as String,
      destinationLat: (json['destinationLat'] as num).toDouble(),
      destinationLng: (json['destinationLng'] as num).toDouble(),
      eventTime: DateTime.parse(json['eventTime'] as String),
      status: eventStatusFromString(statusRaw),
      statusRaw: statusRaw,
      planningStatus: json['planningStatus'] as String? ?? 'NOT_STARTED',
      assignmentGenerated: json['assignmentGenerated'] as bool? ?? false,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      currentUserParticipantRole:
          viewerRoleRaw == null ? null : participantRoleFromString(viewerRoleRaw),
      currentUserParticipantStatus: viewerStatusRaw == null
          ? null
          : participantStatusFromString(viewerStatusRaw),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CreateEventRequest {
  const CreateEventRequest({
    required this.title,
    this.description,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.eventTime,
  });

  final String title;
  final String? description;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final DateTime eventTime;

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null && description!.isNotEmpty) 'description': description,
        'destinationAddress': destinationAddress,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'eventTime': eventTime.toUtc().toIso8601String(),
      };
}

class UpdateEventRequest {
  const UpdateEventRequest({
    this.title,
    this.description,
    this.destinationAddress,
    this.destinationLat,
    this.destinationLng,
    this.eventTime,
  });

  final String? title;
  final String? description;
  final String? destinationAddress;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime? eventTime;

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (destinationAddress != null) 'destinationAddress': destinationAddress,
        if (destinationLat != null) 'destinationLat': destinationLat,
        if (destinationLng != null) 'destinationLng': destinationLng,
        if (eventTime != null) 'eventTime': eventTime!.toUtc().toIso8601String(),
      };
}
