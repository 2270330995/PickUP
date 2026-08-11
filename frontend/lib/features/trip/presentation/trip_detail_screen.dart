import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/eta_format.dart';
import '../../../core/launch/external_url_launcher.dart';
import '../../../core/network/api_exception.dart';
import '../../assignment/data/assignment_api.dart';
import '../data/trip_api.dart';
import '../data/trip_dtos.dart';
import '../data/trip_execution_dtos.dart';

/// Display mode for [TripDetailScreen]. The same widget is reused by the driver
/// view (full stop list + execution actions), the passenger view (highlight my stop),
/// and the organizer monitor view (read-only, no execution actions).
enum TripViewMode { driver, passenger, monitor }

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({
    super.key,
    required this.tripId,
    required this.mode,
    this.currentUserId,
    this.appBarTitle,
  });

  final String tripId;
  final TripViewMode mode;

  /// Used in passenger mode to highlight the stop that belongs to the viewer.
  final String? currentUserId;

  final String? appBarTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle ??
            switch (mode) {
              TripViewMode.driver => 'Driver trip',
              TripViewMode.passenger => 'My ride',
              TripViewMode.monitor => 'Trip progress',
            }),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tripDetailProvider(tripId)),
        child: tripAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load trip'),
            ],
          ),
          data: (trip) => _TripBody(
            trip: trip,
            mode: mode,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }
}

class _TripBody extends ConsumerStatefulWidget {
  const _TripBody({
    required this.trip,
    required this.mode,
    required this.currentUserId,
  });

  final TripResponse trip;
  final TripViewMode mode;
  final String? currentUserId;

  @override
  ConsumerState<_TripBody> createState() => _TripBodyState();
}

class _TripBodyState extends ConsumerState<_TripBody> {
  bool _busy = false;

  TripResponse get _trip => widget.trip;
  bool get _isDriverMode => widget.mode == TripViewMode.driver;

  Future<void> _run(Future<TripResponse> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(tripDetailProvider(_trip.id));
      ref.invalidate(myTripsProvider);
      ref.invalidate(eventAssignmentPlanProvider(_trip.eventId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(okMsg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _run(
        () => ref.read(tripApiProvider).start(_trip.id),
        'Trip started',
      );

  Future<void> _complete() => _run(
        () => ref.read(tripApiProvider).complete(_trip.id),
        'Trip completed',
      );

  Future<void> _resolveCurrentStop(StopAction action) {
    final currentId = _trip.currentStopId;
    if (currentId == null) return Future.value();
    return _run(
      () => ref.read(tripApiProvider).updateStop(
            _trip.id,
            currentId,
            UpdateTripStopRequest(action: action),
          ),
      switch (action) {
        StopAction.pickUp => 'Marked picked up',
        StopAction.skip => 'Stop skipped',
        StopAction.cancel => 'Stop cancelled',
      },
    );
  }

  Future<void> _launchNavigation() async {
    final url = _trip.navigationUrl;
    if (url == null || url.isEmpty) return;
    await launchExternalUrl(context, url);
  }

  TripStopSummary? _currentStop(TripResponse trip) {
    if (trip.currentStopId == null) return null;
    for (final stop in trip.stops) {
      if (stop.id == trip.currentStopId) return stop;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = _trip;
    final currentStop = _currentStop(trip);
    final navAddress = trip.navigationAddress(currentStop);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(trip: trip),
        const SizedBox(height: 16),
        if (widget.mode == TripViewMode.passenger &&
            widget.currentUserId != null)
          _PassengerRideStatusCard(
            trip: trip,
            currentUserId: widget.currentUserId!,
          ),
        if (!_isDriverMode && trip.hasNavigation)
          _NavigationContextBanner(
            trip: trip,
            address: navAddress,
          ),
        if (_isDriverMode && trip.status == TripStatus.assigned)
          _StartTripCard(busy: _busy, onStart: _start),
        if (_isDriverMode && trip.hasNavigation) ...[
          const SizedBox(height: 16),
          _NavigationTargetCard(
            trip: trip,
            address: navAddress,
            busy: _busy,
            onLaunch: _launchNavigation,
          ),
        ],
        if (_isDriverMode &&
            trip.status == TripStatus.inProgress &&
            currentStop != null) ...[
          const SizedBox(height: 16),
          _CurrentStopCard(
            stop: currentStop,
            busy: _busy,
            onPickUp: () => _resolveCurrentStop(StopAction.pickUp),
            onSkip: () => _resolveCurrentStop(StopAction.skip),
            onCancel: () => _resolveCurrentStop(StopAction.cancel),
          ),
        ],
        if (_isDriverMode && trip.status == TripStatus.allPassengersPicked) ...[
          const SizedBox(height: 16),
          _CompleteTripCard(busy: _busy, onComplete: _complete),
        ],
        if (_isDriverMode && trip.status == TripStatus.completed) ...[
          const SizedBox(height: 16),
          _TripCompletedCard(completedAt: trip.completedAt),
        ],
        const SizedBox(height: 8),
        Text(
          _isDriverMode || widget.mode == TripViewMode.monitor
              ? 'Pickup order (${trip.stops.length})'
              : 'Trip stops (${trip.stops.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (trip.stops.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No pickups on this trip.'),
          )
        else
          ...trip.stops.map((stop) => _StopTile(
                stop: stop,
                isCurrent: stop.id == trip.currentStopId,
                isMine: widget.mode == TripViewMode.passenger &&
                    widget.currentUserId != null &&
                    stop.userId == widget.currentUserId,
              )),
      ],
    );
  }
}

class _NavigationTargetCard extends StatelessWidget {
  const _NavigationTargetCard({
    required this.trip,
    required this.address,
    required this.busy,
    required this.onLaunch,
  });

  final TripResponse trip;
  final String? address;
  final bool busy;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonLabel = trip.navigationTargetType ==
            NavigationTargetType.finalDestination
        ? 'Navigate to destination'
        : 'Start navigation';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.navigation_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    navigationTargetLabel(trip.navigationTargetType),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (trip.navigationLabel != null &&
                trip.navigationLabel!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                trip.navigationLabel!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (address != null && address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(child: Text(address!)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onLaunch,
                icon: const Icon(Icons.map_outlined),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationContextBanner extends StatelessWidget {
  const _NavigationContextBanner({
    required this.trip,
    required this.address,
  });

  final TripResponse trip;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(Icons.navigation_outlined,
            color: theme.colorScheme.primary),
        title: Text(
          trip.navigationLabel ??
              navigationTargetLabel(trip.navigationTargetType),
        ),
        subtitle: address != null && address!.isNotEmpty
            ? Text(address!)
            : Text(navigationTargetLabel(trip.navigationTargetType)),
      ),
    );
  }
}

class _PassengerRideStatusCard extends StatelessWidget {
  const _PassengerRideStatusCard({
    required this.trip,
    required this.currentUserId,
  });

  final TripResponse trip;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myStop = trip.stops.cast<TripStopSummary?>().firstWhere(
          (s) => s?.userId == currentUserId,
          orElse: () => null,
        );
    if (myStop == null) return const SizedBox.shrink();

    final (title, subtitle, icon, color) = switch (trip.status) {
      TripStatus.completed => (
          'Ride completed',
          'Your driver has finished the trip.',
          Icons.check_circle,
          Colors.green,
        ),
      TripStatus.assigned => (
          'Waiting for pickup',
          'Your driver has not started the trip yet.',
          Icons.schedule,
          theme.colorScheme.outline,
        ),
      TripStatus.inProgress when myStop.status == StopStatus.pickedUp => (
          'You have been picked up',
          'Your driver is continuing with other stops.',
          Icons.check_circle,
          Colors.green,
        ),
      TripStatus.inProgress when myStop.status == StopStatus.active => (
          'Driver is on the way',
          'You are the current pickup stop.',
          Icons.directions_car,
          theme.colorScheme.primary,
        ),
      TripStatus.inProgress => (
          'Trip in progress',
          'Your driver is working through the pickup route.',
          Icons.directions_car,
          theme.colorScheme.primary,
        ),
      TripStatus.allPassengersPicked when myStop.status == StopStatus.pickedUp => (
          'Heading to destination',
          trip.navigationLabel ?? 'All passengers are aboard.',
          Icons.flag,
          theme.colorScheme.primary,
        ),
      TripStatus.allPassengersPicked => (
          'Trip wrapping up pickups',
          stopStatusLabel(myStop.status),
          Icons.info_outline,
          theme.colorScheme.outline,
        ),
      _ => (
          tripStatusLabel(trip.status),
          stopStatusLabel(myStop.status),
          Icons.info_outline,
          theme.colorScheme.outline,
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.trip});
  final TripResponse trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.eventTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(trip.eventTime.toLocal().toString(),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 4, children: [
              Chip(label: Text(tripStatusLabel(trip.status))),
              Chip(label: Text('${trip.stops.length} stops')),
              if (trip.startedAt != null)
                Chip(
                  avatar: const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                      'Started ${_formatTime(trip.startedAt!.toLocal())}'),
                ),
              if (trip.completedAt != null)
                Chip(
                  avatar: const Icon(Icons.flag, size: 16),
                  label: Text(
                      'Completed ${_formatTime(trip.completedAt!.toLocal())}'),
                ),
            ]),
            const Divider(height: 24),
            Row(children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Driver: ${trip.driverFullName}')),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.directions_car_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.vehicleSummary.label)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.flag_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.finalDestinationAddress)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StartTripCard extends StatelessWidget {
  const _StartTripCard({required this.busy, required this.onStart});
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to drive?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Starting the trip activates your first stop. '
              'You can mark each passenger picked up, skip a no-show, or cancel a stop.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onStart,
                icon: const Icon(Icons.play_arrow),
                label: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentStopCard extends StatelessWidget {
  const _CurrentStopCard({
    required this.stop,
    required this.busy,
    required this.onPickUp,
    required this.onSkip,
    required this.onCancel,
  });

  final TripStopSummary stop;
  final bool busy;
  final VoidCallback onPickUp;
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: Text('${stop.sequence + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current pickup',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                      Text(
                        stop.userFullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  size: 18, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stop.address,
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ]),
            if (stop.meetingPointName != null &&
                stop.meetingPointName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  stop.meetingPointName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onPickUp,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Picked up'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onSkip,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip (no-show)'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel stop'),
                ),
              ],
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompleteTripCard extends StatelessWidget {
  const _CompleteTripCard({required this.busy, required this.onComplete});
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All passengers picked',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drive to the destination and mark the trip complete when you arrive.',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onComplete,
                icon: const Icon(Icons.flag),
                label: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCompletedCard extends StatelessWidget {
  const _TripCompletedCard({required this.completedAt});
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text('Trip completed'),
        subtitle: Text(
          completedAt == null
              ? 'No further actions required.'
              : 'Completed at ${_formatTime(completedAt!.toLocal())}',
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.isCurrent,
    required this.isMine,
  });
  final TripStopSummary stop;
  final bool isCurrent;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = isCurrent || isMine;
    final highlightFg = isCurrent
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onPrimaryContainer;
    final highlightBg = isCurrent
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.primaryContainer;
    final pickedUpAt = stop.actualDepartureTime ?? stop.actualArrivalTime;
    return Card(
      color: highlight ? highlightBg : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCurrent ? theme.colorScheme.tertiary : null,
          foregroundColor:
              isCurrent ? theme.colorScheme.onTertiary : null,
          child: Text('${stop.sequence + 1}'),
        ),
        title: Text(
          stop.userFullName,
          style: TextStyle(
            color: highlight ? highlightFg : null,
            fontWeight: highlight ? FontWeight.w600 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.address,
              style: TextStyle(color: highlight ? highlightFg : null),
            ),
            if (stop.meetingPointName != null &&
                stop.meetingPointName!.isNotEmpty)
              Text(
                stop.meetingPointName!,
                style: TextStyle(color: highlight ? highlightFg : null),
              ),
            if (pickedUpAt == null)
              Builder(
                builder: (context) {
                  final eta = formatEtaMinutes(stop.etaMinutes);
                  if (eta == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      eta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: highlight ? highlightFg : theme.colorScheme.outline,
                      ),
                    ),
                  );
                },
              ),
            if (pickedUpAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${_actionLabel(stop.status)} at '
                  '${_formatTime(pickedUpAt.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: highlight ? highlightFg : theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: stop.meetingPointName != null &&
            stop.meetingPointName!.isNotEmpty,
        trailing: Chip(label: Text(stopStatusLabel(stop.status))),
      ),
    );
  }
}

String _actionLabel(StopStatus s) {
  switch (s) {
    case StopStatus.pickedUp:
      return 'Picked up';
    case StopStatus.skipped:
      return 'Skipped';
    case StopStatus.cancelled:
      return 'Cancelled';
    case StopStatus.arrived:
      return 'Arrived';
    default:
      return 'Resolved';
  }
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
