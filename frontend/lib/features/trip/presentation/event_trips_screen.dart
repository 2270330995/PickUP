import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/format/eta_format.dart';
import '../../../core/router/route_paths.dart';
import '../../assignment/data/assignment_api.dart';
import '../data/trip_dtos.dart';
import 'ordered_stop_preview.dart';

/// Read-only monitor of all trips for one event. Organizers use it to watch
/// execution progress; confirmed/assigned participants can open it too.
///
/// Pull-to-refresh only — live WebSocket updates are a later phase.
class EventTripsScreen extends ConsumerWidget {
  const EventTripsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(eventAssignmentPlanProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('Event trips')),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(eventAssignmentPlanProvider(eventId)),
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load trips'),
            ],
          ),
          data: (plan) {
            if (plan.trips.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.alt_route_outlined, size: 56),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No trips yet.\n'
                      'Assign passengers to drivers to create trips.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plan.trips.length,
              itemBuilder: (_, i) => _EventTripCard(trip: plan.trips[i]),
            );
          },
        ),
      ),
    );
  }
}

class _EventTripCard extends StatelessWidget {
  const _EventTripCard({required this.trip});
  final TripResponse trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _stopProgress(trip);
    final currentLabel = _currentStopLabel(trip);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(RoutePaths.tripMonitorFor(trip.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.directions_car)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driverFullName,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          trip.vehicleSummary.label,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(label: Text(tripStatusLabel(trip.status))),
                ],
              ),
              const SizedBox(height: 12),
              if (trip.status == TripStatus.assigned && trip.stops.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.route_outlined,
                        size: 18, color: theme.colorScheme.outline),
                    const SizedBox(width: 8),
                    Text(
                      'Pickup order',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OrderedStopPreview(stops: trip.stops),
                if (maxEtaMinutes(trip.stops.map((s) => s.etaMinutes)) case final total?) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Estimated route to last pickup: ~$total min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (currentLabel != null)
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(currentLabel)),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.checklist_rtl,
                      size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.resolved} / ${progress.total} stops resolved',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (trip.startedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Started ${_formatTime(trip.startedAt!.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              if (trip.completedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Completed ${_formatTime(trip.completedAt!.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push(RoutePaths.tripMonitorFor(trip.id)),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopProgress {
  const _StopProgress({required this.resolved, required this.total});
  final int resolved;
  final int total;
}

_StopProgress _stopProgress(TripResponse trip) {
  final total = trip.stops.length;
  if (total == 0) return const _StopProgress(resolved: 0, total: 0);
  final resolved = trip.stops
      .where((s) =>
          s.status == StopStatus.pickedUp ||
          s.status == StopStatus.skipped ||
          s.status == StopStatus.cancelled)
      .length;
  return _StopProgress(resolved: resolved, total: total);
}

String? _currentStopLabel(TripResponse trip) {
  if (trip.status == TripStatus.completed) {
    return 'Trip completed';
  }
  if (trip.hasNavigation) {
    final label = trip.navigationLabel;
    if (label != null && label.isNotEmpty) return label;
  }
  if (trip.status == TripStatus.allPassengersPicked) {
    return 'All pickups done — heading to destination';
  }
  if (trip.currentStopId == null) return null;
  final stop = trip.stops.cast<TripStopSummary?>().firstWhere(
        (s) => s?.id == trip.currentStopId,
        orElse: () => null,
      );
  if (stop == null) return null;
  return 'Current: ${stop.userFullName} (#${stop.sequence + 1})';
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
