import '../../assignment/data/assignment_dtos.dart';
import '../../participant/data/participant_dtos.dart';
import '../../trip/data/trip_dtos.dart';
import '../data/event_dtos.dart';

/// Fixed, ordered hues for the driver color palette. Both the map markers and
/// the legend derive their colors from this same list (via
/// `HSVColor.fromAHSV(1, hue, 1, 1).toColor()` on the legend side, and
/// `BitmapDescriptor.hueX` constants on the marker side) so they never drift
/// out of sync. Cycles via modulo when there are more drivers than colors.
/// Red is deliberately excluded — the destination marker always uses
/// `BitmapDescriptor.hueRed` so it reads as distinct from every driver group.
const List<double> eventMapColorPalette = [
  30, // hueOrange
  60, // hueYellow
  120, // hueGreen
  180, // hueCyan
  210, // hueAzure
  270, // hueViolet
  300, // hueMagenta
  330, // hueRose
];

enum EventMapMarkerKind { destination, driver, passenger, unassigned }

class EventMapMarkerSpec {
  const EventMapMarkerSpec({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    required this.kind,
    this.colorGroupIndex,
  });

  final String id;
  final double lat;
  final double lng;
  final String label;
  final EventMapMarkerKind kind;

  /// Index into [eventMapColorPalette] (mod its length). Null for
  /// [EventMapMarkerKind.destination] and [EventMapMarkerKind.unassigned].
  final int? colorGroupIndex;
}

/// Statuses that no longer represent an active attendee — mirrors the
/// active/inactive split event_detail_screen.dart already applies before
/// rendering participant rows, so a cancelled/rejected/no-show participant's
/// stale pickup location never shows up on the map.
const Set<ParticipantStatus> _inactiveStatuses = {
  ParticipantStatus.cancelled,
  ParticipantStatus.rejected,
  ParticipantStatus.noShow,
};

/// Finds the participant driving [trip]. A trip's driver is either
/// Contact-backed (`driverParticipantId` set, matched by participant id) or a
/// legacy self-joined user (`driverId` set, matched by participant userId) —
/// see TripResponse's doc comments. Returns null if neither reference matches
/// any participant (e.g. the two providers this data comes from are
/// momentarily out of sync).
EventParticipantResponse? _driverFor(
  TripResponse trip,
  List<EventParticipantResponse> participants,
) {
  for (final p in participants) {
    if (trip.driverParticipantId != null && p.id == trip.driverParticipantId) {
      return p;
    }
  }
  for (final p in participants) {
    if (trip.driverId != null && p.userId == trip.driverId) {
      return p;
    }
  }
  return null;
}

List<EventMapMarkerSpec> buildEventMapMarkers({
  required EventResponse event,
  required List<EventParticipantResponse> participants,
  required AssignmentPlanResponse plan,
}) {
  final markers = <EventMapMarkerSpec>[
    EventMapMarkerSpec(
      id: 'destination',
      lat: event.destinationLat,
      lng: event.destinationLng,
      label: event.destinationAddress,
      kind: EventMapMarkerKind.destination,
    ),
  ];

  final placedParticipantIds = <String>{};

  for (var tripIndex = 0; tripIndex < plan.trips.length; tripIndex++) {
    final trip = plan.trips[tripIndex];
    final colorGroupIndex = tripIndex % eventMapColorPalette.length;

    final driver = _driverFor(trip, participants);
    if (driver != null) {
      placedParticipantIds.add(driver.id);
      if (driver.pickupLat != null && driver.pickupLng != null) {
        markers.add(EventMapMarkerSpec(
          id: 'driver-${driver.id}',
          lat: driver.pickupLat!,
          lng: driver.pickupLng!,
          label: driver.displayLabel,
          kind: EventMapMarkerKind.driver,
          colorGroupIndex: colorGroupIndex,
        ));
      }
    }

    for (final stop in trip.stops) {
      placedParticipantIds.add(stop.participantId);
      markers.add(EventMapMarkerSpec(
        id: 'stop-${stop.id}',
        lat: stop.lat,
        lng: stop.lng,
        label: stop.userFullName,
        kind: EventMapMarkerKind.passenger,
        colorGroupIndex: colorGroupIndex,
      ));
    }
  }

  for (final participant in participants) {
    if (placedParticipantIds.contains(participant.id)) continue;
    if (_inactiveStatuses.contains(participant.status)) continue;
    if (participant.role != ParticipantRole.driver &&
        participant.role != ParticipantRole.passenger) {
      continue;
    }
    if (participant.pickupLat == null || participant.pickupLng == null) {
      continue;
    }
    markers.add(EventMapMarkerSpec(
      id: 'unassigned-${participant.id}',
      lat: participant.pickupLat!,
      lng: participant.pickupLng!,
      label: participant.displayLabel,
      kind: EventMapMarkerKind.unassigned,
    ));
  }

  return markers;
}
