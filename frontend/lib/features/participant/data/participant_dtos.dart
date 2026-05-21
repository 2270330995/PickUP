enum ParticipantRole { organizer, driver, passenger, independentAttendee, unknown }

ParticipantRole participantRoleFromString(String? raw) {
  switch (raw) {
    case 'ORGANIZER':
      return ParticipantRole.organizer;
    case 'DRIVER':
      return ParticipantRole.driver;
    case 'PASSENGER':
      return ParticipantRole.passenger;
    case 'INDEPENDENT_ATTENDEE':
      return ParticipantRole.independentAttendee;
    default:
      return ParticipantRole.unknown;
  }
}

String participantRoleToString(ParticipantRole r) {
  switch (r) {
    case ParticipantRole.organizer:
      return 'ORGANIZER';
    case ParticipantRole.driver:
      return 'DRIVER';
    case ParticipantRole.passenger:
      return 'PASSENGER';
    case ParticipantRole.independentAttendee:
      return 'INDEPENDENT_ATTENDEE';
    case ParticipantRole.unknown:
      return 'UNKNOWN';
  }
}

String participantRoleLabel(ParticipantRole r) {
  switch (r) {
    case ParticipantRole.organizer:
      return 'Organizer';
    case ParticipantRole.driver:
      return 'Driver';
    case ParticipantRole.passenger:
      return 'Passenger';
    case ParticipantRole.independentAttendee:
      return 'Self-arriving';
    case ParticipantRole.unknown:
      return 'Unknown';
  }
}

enum ParticipantStatus {
  invited,
  requested,
  approved,
  rejected,
  confirmed,
  assigned,
  checkedIn,
  pickedUp,
  arrived,
  cancelled,
  noShow,
  unknown,
}

ParticipantStatus participantStatusFromString(String? raw) {
  switch (raw) {
    case 'INVITED':
      return ParticipantStatus.invited;
    case 'REQUESTED':
      return ParticipantStatus.requested;
    case 'APPROVED':
      return ParticipantStatus.approved;
    case 'REJECTED':
      return ParticipantStatus.rejected;
    case 'CONFIRMED':
      return ParticipantStatus.confirmed;
    case 'ASSIGNED':
      return ParticipantStatus.assigned;
    case 'CHECKED_IN':
      return ParticipantStatus.checkedIn;
    case 'PICKED_UP':
      return ParticipantStatus.pickedUp;
    case 'ARRIVED':
      return ParticipantStatus.arrived;
    case 'CANCELLED':
      return ParticipantStatus.cancelled;
    case 'NO_SHOW':
      return ParticipantStatus.noShow;
    default:
      return ParticipantStatus.unknown;
  }
}

String participantStatusLabel(ParticipantStatus s) {
  switch (s) {
    case ParticipantStatus.invited:
      return 'Invited';
    case ParticipantStatus.requested:
      return 'Pending';
    case ParticipantStatus.approved:
      return 'Approved';
    case ParticipantStatus.rejected:
      return 'Rejected';
    case ParticipantStatus.confirmed:
      return 'Confirmed';
    case ParticipantStatus.assigned:
      return 'Assigned';
    case ParticipantStatus.checkedIn:
      return 'Checked in';
    case ParticipantStatus.pickedUp:
      return 'Picked up';
    case ParticipantStatus.arrived:
      return 'Arrived';
    case ParticipantStatus.cancelled:
      return 'Cancelled';
    case ParticipantStatus.noShow:
      return 'No-show';
    case ParticipantStatus.unknown:
      return 'Unknown';
  }
}

class EventParticipantResponse {
  const EventParticipantResponse({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.role,
    required this.roleRaw,
    required this.status,
    required this.statusRaw,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.vehicleId,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String userFullName;
  final String userEmail;
  final ParticipantRole role;
  final String roleRaw;
  final ParticipantStatus status;
  final String statusRaw;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? vehicleId;
  final DateTime createdAt;

  factory EventParticipantResponse.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['role'] as String? ?? 'UNKNOWN';
    final statusRaw = json['status'] as String? ?? 'UNKNOWN';
    return EventParticipantResponse(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      userFullName: json['userFullName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      role: participantRoleFromString(roleRaw),
      roleRaw: roleRaw,
      status: participantStatusFromString(statusRaw),
      statusRaw: statusRaw,
      pickupAddress: json['pickupAddress'] as String?,
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      vehicleId: json['vehicleId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class JoinEventRequest {
  const JoinEventRequest({
    required this.role,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
  });

  final ParticipantRole role;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  Map<String, dynamic> toJson() => {
        'role': participantRoleToString(role),
        if (pickupAddress != null && pickupAddress!.isNotEmpty)
          'pickupAddress': pickupAddress,
        if (pickupLat != null) 'pickupLat': pickupLat,
        if (pickupLng != null) 'pickupLng': pickupLng,
      };
}
