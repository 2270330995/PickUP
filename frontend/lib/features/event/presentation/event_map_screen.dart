import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../assignment/data/assignment_api.dart';
import '../../assignment/data/assignment_dtos.dart';
import '../../participant/data/participant_api.dart';
import '../../participant/data/participant_dtos.dart';
import '../data/event_api.dart';
import '../data/event_dtos.dart';
import 'event_map_markers.dart';

/// Standalone map showing the event destination and every participant's
/// pickup location, color-grouped by which driver they're assigned to.
///
/// Deliberately reads a point-in-time snapshot of "where is everyone" via
/// [buildEventMapMarkers] rather than embedding any live-location logic here
/// — if live location sharing is added later, only that data-building step
/// needs to change, not this rendering code.
class EventMapScreen extends ConsumerWidget {
  const EventMapScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('Event map')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorBody(err: err, fallback: 'Failed to load event'),
        data: (event) {
          final participantsAsync = ref.watch(eventParticipantsProvider(eventId));
          return participantsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                _ErrorBody(err: err, fallback: 'Failed to load participants'),
            data: (participants) {
              final planAsync = ref.watch(eventAssignmentPlanProvider(eventId));
              return planAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorBody(err: err, fallback: 'Failed to load trips'),
                data: (plan) => _EventMapBody(
                  event: event,
                  participants: participants,
                  plan: plan,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.err, required this.fallback});
  final Object err;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(err is ApiException ? (err as ApiException).message : fallback),
      ),
    );
  }
}

/// Converts one of [eventMapColorPalette]'s hues into a Flutter [Color], so
/// the legend and the generated marker bitmaps below both derive from the
/// same source and never drift out of sync.
Color eventMapHueToColor(double hue) => HSVColor.fromAHSV(1, hue, 1, 1).toColor();

const double _unassignedHue = 200; // a neutral blue-grey, not in the driver palette
const _destinationColor = Colors.red;

Color _colorFor(EventMapMarkerSpec spec) => switch (spec.kind) {
      EventMapMarkerKind.destination => _destinationColor,
      EventMapMarkerKind.unassigned => eventMapHueToColor(_unassignedHue),
      EventMapMarkerKind.driver ||
      EventMapMarkerKind.passenger =>
        eventMapHueToColor(
          eventMapColorPalette[(spec.colorGroupIndex ?? 0) % eventMapColorPalette.length],
        ),
    };

String _truncateLabel(String label, {int maxLength = 18}) =>
    label.length <= maxLength ? label : '${label.substring(0, maxLength - 1)}…';

/// A generated marker icon plus the anchor fraction that keeps the dot —
/// not the whole label pill — pinned to the marker's actual coordinate.
class _MarkerIcon {
  const _MarkerIcon({required this.bitmap, required this.anchor});
  final BitmapDescriptor bitmap;
  final Offset anchor;
}

/// The dot's outline shape. Drivers get a diamond so they stand out from
/// their own passengers at a glance even though both share the trip's color;
/// everyone else (passengers, unassigned, the destination) stays a circle.
enum _DotShape { circle, diamond }

Path _dotPath(_DotShape shape, Offset center, double radius) {
  switch (shape) {
    case _DotShape.circle:
      return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    case _DotShape.diamond:
      return Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy)
        ..close();
  }
}

/// Renders a colored dot with the person's name in a label pill beside it,
/// and encodes it as a PNG so it can be used as a [BitmapDescriptor.bytes]
/// marker icon — showing the name directly on the map, not just on tap.
///
/// google_maps_flutter's web renderer (google_maps_flutter_web) does not
/// implement [BitmapDescriptor.defaultMarkerWithHue], and neither web nor the
/// base [Marker] type support a persistent text label the way some native map
/// SDKs do — every marker using hue silently falls back to the plain default
/// red pin on web, even though it works on Android/iOS. Baking color *and*
/// text into a generated bitmap icon instead works identically everywhere.
Future<_MarkerIcon> _labeledMarkerIcon({
  required Color color,
  required String label,
  double dotDiameter = 22,
  _DotShape shape = _DotShape.circle,
}) async {
  const fontSize = 12.0;
  const hPadding = 6.0;
  const vPadding = 3.0;
  const gap = 4.0;
  const dotBorder = 2.0;

  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final pillWidth = textPainter.width + hPadding * 2;
  final pillHeight = textPainter.height + vPadding * 2;
  final totalWidth = dotDiameter + gap + pillWidth;
  final totalHeight = math.max(dotDiameter, pillHeight);
  final dotCenter = Offset(dotDiameter / 2, totalHeight / 2);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawPath(
    _dotPath(shape, dotCenter, dotDiameter / 2 - dotBorder),
    Paint()..color = color,
  );
  canvas.drawPath(
    _dotPath(shape, dotCenter, dotDiameter / 2 - dotBorder / 2),
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotBorder,
  );

  final pillRect = Rect.fromLTWH(
    dotDiameter + gap,
    (totalHeight - pillHeight) / 2,
    pillWidth,
    pillHeight,
  );
  final pillRRect = RRect.fromRectAndRadius(pillRect, Radius.circular(pillHeight / 2));
  canvas.drawRRect(pillRRect, Paint()..color = Colors.white);
  canvas.drawRRect(
    pillRRect,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  textPainter.paint(canvas, Offset(pillRect.left + hPadding, pillRect.top + vPadding));

  final picture = recorder.endRecording();
  final image = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return _MarkerIcon(
    bitmap: BitmapDescriptor.bytes(byteData!.buffer.asUint8List()),
    // Anchor on the dot's center, not the pill/label — that's the point
    // that actually has to sit on the real lat/lng.
    anchor: Offset((dotDiameter / 2) / totalWidth, 0.5),
  );
}

_DotShape _shapeFor(EventMapMarkerSpec spec) =>
    spec.kind == EventMapMarkerKind.driver ? _DotShape.diamond : _DotShape.circle;

Future<Map<String, _MarkerIcon>> _loadMarkerIcons(List<EventMapMarkerSpec> specs) async {
  final entries = await Future.wait(specs.map((spec) async {
    final icon = await _labeledMarkerIcon(
      color: _colorFor(spec),
      label: _truncateLabel(spec.label),
      dotDiameter: spec.kind == EventMapMarkerKind.destination ? 28 : 22,
      shape: _shapeFor(spec),
    );
    return MapEntry(spec.id, icon);
  }));
  return Map.fromEntries(entries);
}

class _EventMapBody extends StatefulWidget {
  const _EventMapBody({
    required this.event,
    required this.participants,
    required this.plan,
  });

  final EventResponse event;
  final List<EventParticipantResponse> participants;
  final AssignmentPlanResponse plan;

  @override
  State<_EventMapBody> createState() => _EventMapBodyState();
}

class _EventMapBodyState extends State<_EventMapBody> {
  GoogleMapController? _controller;
  late final List<EventMapMarkerSpec> _markerSpecs;
  Map<String, _MarkerIcon>? _icons;

  @override
  void initState() {
    super.initState();
    _markerSpecs = buildEventMapMarkers(
      event: widget.event,
      participants: widget.participants,
      plan: widget.plan,
    );
    _loadMarkerIcons(_markerSpecs).then((icons) {
      if (mounted) setState(() => _icons = icons);
    });
  }

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    if (icons == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final markerSpecs = _markerSpecs;
    final markers = markerSpecs.map((spec) => _toMarker(spec, icons)).toSet();

    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.event.destinationLat, widget.event.destinationLng),
              zoom: 12,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _controller = controller;
              _fitBounds(markerSpecs);
            },
          ),
        ),
        _Legend(plan: widget.plan),
      ],
    );
  }

  Marker _toMarker(EventMapMarkerSpec spec, Map<String, _MarkerIcon> icons) {
    final icon = icons[spec.id];
    return Marker(
      markerId: MarkerId(spec.id),
      position: LatLng(spec.lat, spec.lng),
      icon: icon?.bitmap ?? BitmapDescriptor.defaultMarker,
      anchor: icon?.anchor ?? const Offset(0.5, 1.0),
      infoWindow: InfoWindow(title: spec.label),
    );
  }

  void _fitBounds(List<EventMapMarkerSpec> markerSpecs) {
    final controller = _controller;
    if (controller == null || markerSpecs.isEmpty) return;

    var minLat = markerSpecs.first.lat;
    var maxLat = markerSpecs.first.lat;
    var minLng = markerSpecs.first.lng;
    var maxLng = markerSpecs.first.lng;
    for (final spec in markerSpecs) {
      if (spec.lat < minLat) minLat = spec.lat;
      if (spec.lat > maxLat) maxLat = spec.lat;
      if (spec.lng < minLng) minLng = spec.lng;
      if (spec.lng > maxLng) maxLng = spec.lng;
    }

    // A single marker (or several at ~the same point) produces a zero-area
    // box, which would otherwise zoom the camera in to its maximum level with
    // no surrounding context. Pad to a minimum ~1km span in that case.
    const minSpanDegrees = 0.01;
    if (maxLat - minLat < minSpanDegrees) {
      final mid = (minLat + maxLat) / 2;
      minLat = mid - minSpanDegrees / 2;
      maxLat = mid + minSpanDegrees / 2;
    }
    if (maxLng - minLng < minSpanDegrees) {
      final mid = (minLng + maxLng) / 2;
      minLng = mid - minSpanDegrees / 2;
      maxLng = mid + minSpanDegrees / 2;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.plan});
  final AssignmentPlanResponse plan;

  @override
  Widget build(BuildContext context) {
    if (plan.trips.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (var i = 0; i < plan.trips.length; i++)
            _LegendEntry(
              color: eventMapHueToColor(eventMapColorPalette[i % eventMapColorPalette.length]),
              label: plan.trips[i].driverFullName,
            ),
          _LegendEntry(
            color: eventMapHueToColor(_unassignedHue),
            label: 'Not yet assigned',
          ),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
