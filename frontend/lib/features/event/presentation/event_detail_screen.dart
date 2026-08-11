import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../dashboard/data/dashboard_api.dart';
import '../../dashboard/data/dashboard_dtos.dart';
import '../../assignment/data/assignment_api.dart';
import '../../participant/data/participant_api.dart';
import '../../participant/data/participant_dtos.dart';
import '../../location/data/resolved_address.dart';
import '../../location/presentation/address_autocomplete_field.dart';
import '../../location/presentation/location_picker_sheet.dart';
import '../../participant/presentation/pickup_address_sheet.dart';
import '../../trip/data/trip_api.dart';
import '../../trip/data/trip_dtos.dart';
import '../../user/data/user_api.dart';
import '../../vehicle/presentation/vehicle_picker_sheet.dart';
import '../data/event_api.dart';
import '../data/event_dtos.dart';
import 'add_from_people_sheet.dart';
import 'organizer_participant_edit_sheet.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        leading: context.canPop()
            ? const BackButton()
            : IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Dashboard',
                onPressed: () => context.go(RoutePaths.organizer),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventDetailProvider(eventId));
          ref.invalidate(eventParticipantsProvider(eventId));
          ref.invalidate(eventDashboardProvider(eventId));
        },
        child: eventAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load event'),
            ],
          ),
          data: (event) => _EventDetailBody(event: event),
        ),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  const _EventDetailBody({required this.event});
  final EventResponse event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final participantsAsync = ref.watch(eventParticipantsProvider(event.id));
    final dashboardAsync = ref.watch(eventDashboardProvider(event.id));

    return me.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text(err is ApiException ? err.message : 'Failed to load')),
      data: (currentUser) {
        final isOrganizer = currentUser.id == event.organizerId;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(event: event, isOrganizer: isOrganizer),
            const SizedBox(height: 16),
            participantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(err is ApiException ? err.message : 'Failed to load'),
                    data: (participants) {
                      final myParticipant = participants.firstWhere(
                        (p) => p.userId == currentUser.id,
                        orElse: () => _emptyParticipant(),
                      );
                      final hasJoined = myParticipant.id.isNotEmpty;

                      final inactive = {
                        ParticipantStatus.cancelled,
                        ParticipantStatus.rejected,
                        ParticipantStatus.noShow,
                      };
                      final active = participants
                          .where((p) => !inactive.contains(p.status))
                          .toList();
                      final cancelled = participants
                          .where((p) => inactive.contains(p.status))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Participant-first ordering: surface "Your status" before
                          // the broader event snapshot so participants see where
                          // they stand the moment they open the event.
                          if (hasJoined)
                            _MyParticipationCard(eventId: event.id, participant: myParticipant),
                          if (!hasJoined && event.status == EventStatus.open)
                            _JoinCard(eventId: event.id),
                          const SizedBox(height: 16),
                          dashboardAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (d) => _DashboardCard(data: d),
                          ),
                          const SizedBox(height: 16),
                          if (isOrganizer)
                            _OrganizerActions(event: event)
                          else if (hasJoined &&
                              myParticipant.role != ParticipantRole.organizer &&
                              _canViewEventTrips(myParticipant.status))
                            _EventTripsLink(eventId: event.id),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Participants (${active.length})',
                                    style: Theme.of(context).textTheme.titleMedium),
                              ),
                              if (isOrganizer)
                                TextButton.icon(
                                  icon: const Icon(Icons.person_add_alt_1_outlined),
                                  label: const Text('Add from People'),
                                  onPressed: () async {
                                    final activeContactIds = participants
                                        .where((p) => p.contactId != null)
                                        .where((p) => !inactive.contains(p.status))
                                        .map((p) => p.contactId!)
                                        .toSet();
                                    final added = await showAddFromPeopleSheet(
                                      context,
                                      eventId: event.id,
                                      alreadyActiveContactIds: activeContactIds,
                                    );
                                    if (added == true) {
                                      ref.invalidate(eventParticipantsProvider(event.id));
                                      ref.invalidate(eventDashboardProvider(event.id));
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (active.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No active participants yet.'),
                            ),
                          ...active.map((p) => _ParticipantTile(
                                event: event,
                                participant: p,
                                isOrganizer: isOrganizer,
                                currentUserId: currentUser.id,
                              )),
                          if (cancelled.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text('Cancelled / Rejected (${cancelled.length})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    )),
                            const SizedBox(height: 8),
                            ...cancelled.map((p) => _ParticipantTile(
                                  event: event,
                                  participant: p,
                                  isOrganizer: isOrganizer,
                                  currentUserId: currentUser.id,
                                )),
                          ],
                        ],
                      );
                    },
            ),
          ],
        );
      },
    );
  }

  static bool _canViewEventTrips(ParticipantStatus status) {
    return status == ParticipantStatus.confirmed ||
        status == ParticipantStatus.assigned ||
        status == ParticipantStatus.pickedUp ||
        status == ParticipantStatus.arrived ||
        status == ParticipantStatus.checkedIn;
  }

  EventParticipantResponse _emptyParticipant() {
    return EventParticipantResponse(
      id: '',
      eventId: event.id,
      userId: '',
      displayName: '',
      userFullName: '',
      userEmail: '',
      role: ParticipantRole.unknown,
      roleRaw: '',
      status: ParticipantStatus.unknown,
      statusRaw: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.event, required this.isOrganizer});
  final EventResponse event;
  final bool isOrganizer;

  bool get _canEditDestination =>
      isOrganizer &&
      (event.status == EventStatus.draft ||
          event.status == EventStatus.open ||
          event.status == EventStatus.closed);

  Future<void> _editDestination(BuildContext context, WidgetRef ref) async {
    final result = await showLocationPickerSheet(
      context,
      title: 'Event destination',
      subtitle: 'Where is everyone heading?',
      fieldLabel: 'Destination address',
      currentAddress: event.destinationAddress,
      currentLat: event.destinationLat,
      currentLng: event.destinationLng,
      confirmLabel: 'Save destination',
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(eventApiProvider).update(
            event.id,
            UpdateEventRequest(
              destinationAddress: result.formattedAddress,
              destinationLat: result.lat,
              destinationLng: result.lng,
            ),
          );
      ref.invalidate(eventDetailProvider(event.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination updated')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myStatus = event.currentUserParticipantStatus;
    final myRole = event.currentUserParticipantRole;
    final showStatusChip = myStatus != null && myStatus != ParticipantStatus.unknown;
    final showRoleChip = myRole != null &&
        myRole != ParticipantRole.unknown &&
        myRole != ParticipantRole.organizer;
    final statusColors = _headerStatusColors(theme, myStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Organizer: ${event.organizerName}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.event, size: 18),
              const SizedBox(width: 8),
              Text(event.eventTime.toLocal().toString()),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(event.destinationAddress)),
              if (_canEditDestination)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit destination',
                  onPressed: () => _editDestination(context, ref),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 4, children: [
              if (showStatusChip)
                Chip(
                  backgroundColor: statusColors.background,
                  avatar: Icon(Icons.how_to_reg,
                      size: 18, color: statusColors.foreground),
                  label: Text(
                    'You: ${participantStatusLabel(myStatus)}',
                    style: TextStyle(color: statusColors.foreground),
                  ),
                ),
              if (showRoleChip)
                Chip(label: Text(participantRoleLabel(myRole))),
              Chip(label: Text(eventStatusLabel(event.status))),
              Chip(label: Text('${event.participantCount} participants')),
            ]),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(event.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderStatusColors {
  const _HeaderStatusColors({required this.background, required this.foreground});
  final Color? background;
  final Color? foreground;
}

_HeaderStatusColors _headerStatusColors(ThemeData theme, ParticipantStatus? status) {
  final scheme = theme.colorScheme;
  switch (status) {
    case ParticipantStatus.confirmed:
    case ParticipantStatus.ready:
    case ParticipantStatus.checkedIn:
    case ParticipantStatus.pickedUp:
    case ParticipantStatus.arrived:
      return _HeaderStatusColors(
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    case ParticipantStatus.approved:
    case ParticipantStatus.assigned:
      return _HeaderStatusColors(
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      );
    case ParticipantStatus.requested:
    case ParticipantStatus.invited:
      return _HeaderStatusColors(
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    case ParticipantStatus.rejected:
    case ParticipantStatus.cancelled:
    case ParticipantStatus.noShow:
      return _HeaderStatusColors(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    case ParticipantStatus.unknown:
    case null:
      return const _HeaderStatusColors(background: null, foreground: null);
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.data});
  final EventDashboardResponse data;

  @override
  Widget build(BuildContext context) {
    final t = data.totals;
    final s = data.seats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Snapshot', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _ChipStat(label: 'Confirmed drivers', value: t.confirmedDrivers),
              _ChipStat(label: 'Passengers', value: t.passengersNeedingRides),
              _ChipStat(label: 'Self-arriving', value: t.independentAttendees),
              _ChipStat(label: 'Pending', value: t.pendingRequests),
              _ChipStat(label: 'Seats available', value: s.totalSeatsAvailable),
              _ChipStat(label: 'Seat surplus', value: s.seatsSurplus),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _JoinCard extends ConsumerStatefulWidget {
  const _JoinCard({required this.eventId});
  final String eventId;

  @override
  ConsumerState<_JoinCard> createState() => _JoinCardState();
}

class _JoinCardState extends ConsumerState<_JoinCard> {
  ParticipantRole _role = ParticipantRole.passenger;
  bool _submitting = false;
  ResolvedAddress? _pickupLocation;

  bool get _needsPickup => _role == ParticipantRole.passenger;

  Future<void> _join() async {
    if (_needsPickup && _pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your pickup address from suggestions')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final pickup = _pickupLocation;
      await ref.read(participantApiProvider).selfJoin(
            widget.eventId,
            JoinEventRequest(
              role: _role,
              pickupAddress: _needsPickup ? pickup!.formattedAddress : null,
              pickupLat: _needsPickup ? pickup!.lat : null,
              pickupLng: _needsPickup ? pickup!.lng : null,
            ),
          );
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _refreshAll() {
    ref.invalidate(eventParticipantsProvider(widget.eventId));
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventDashboardProvider(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join this event', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<ParticipantRole>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Join as',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: ParticipantRole.passenger, child: Text('Passenger')),
                DropdownMenuItem(
                    value: ParticipantRole.driver, child: Text('Driver')),
                DropdownMenuItem(
                    value: ParticipantRole.independentAttendee,
                    child: Text('Going on my own')),
              ],
              onChanged: (v) => setState(() => _role = v ?? ParticipantRole.passenger),
            ),
            if (_needsPickup) ...[
              const SizedBox(height: 12),
              AddressAutocompleteField(
                labelText: 'Pickup address',
                helperText: 'Start typing, then pick a suggestion',
                onSelected: (value) => setState(() => _pickupLocation = value),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _join,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request to join'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyParticipationCard extends ConsumerStatefulWidget {
  const _MyParticipationCard({required this.eventId, required this.participant});
  final String eventId;
  final EventParticipantResponse participant;

  @override
  ConsumerState<_MyParticipationCard> createState() => _MyParticipationCardState();
}

class _MyParticipationCardState extends ConsumerState<_MyParticipationCard> {
  bool _working = false;

  void _refreshAll() {
    ref.invalidate(eventParticipantsProvider(widget.eventId));
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventDashboardProvider(widget.eventId));
  }

  Future<void> _act(Future<void> Function() action, String successMsg) async {
    setState(() => _working = true);
    try {
      await action();
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pickVehicle() async {
    final result = await showVehiclePickerSheet(
      context,
      currentVehicleId: widget.participant.vehicleId,
      // Don't let the driver clear the linkage once they're already assigned to a trip;
      // backend enforces this too but pre-empting in UI is friendlier.
      allowClear: widget.participant.status != ParticipantStatus.assigned,
    );
    if (result == null || !mounted) return;
    await _act(
      () => ref
          .read(participantApiProvider)
          .setVehicle(widget.eventId, widget.participant.id, result.vehicleId)
          .then((_) {}),
      result.vehicleId == null ? 'Vehicle cleared' : 'Vehicle selected',
    );
  }

  Future<void> _editPickup() async {
    final p = widget.participant;
    final result = await showPickupAddressSheet(
      context,
      currentAddress: p.pickupAddress,
      currentLat: p.pickupLat,
      currentLng: p.pickupLng,
    );
    if (result == null || !mounted) return;
    await _act(
      () => ref.read(participantApiProvider).setPickup(
            widget.eventId,
            p.id,
            UpdateParticipantPickupRequest(
              pickupAddress: result.pickupAddress,
              pickupLat: result.pickupLat,
              pickupLng: result.pickupLng,
            ),
          ).then((_) {}),
      'Pickup location saved',
    );
  }

  Future<void> _editTripStart() async {
    final p = widget.participant;
    final result = await showTripStartAddressSheet(
      context,
      currentAddress: p.pickupAddress,
      currentLat: p.pickupLat,
      currentLng: p.pickupLng,
    );
    if (result == null || !mounted) return;
    await _act(
      () => ref.read(participantApiProvider).setTripStart(
            widget.eventId,
            p.id,
            UpdateParticipantPickupRequest(
              pickupAddress: result.pickupAddress,
              pickupLat: result.pickupLat,
              pickupLng: result.pickupLng,
            ),
          ).then((_) {}),
      'Trip start location saved',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final api = ref.read(participantApiProvider);
    final canConfirm = p.status == ParticipantStatus.approved;
    final canCancel = p.status == ParticipantStatus.requested ||
        p.status == ParticipantStatus.approved ||
        p.status == ParticipantStatus.confirmed;
    final isOrganizerRow = p.role == ParticipantRole.organizer;
    final isDriver = p.role == ParticipantRole.driver;
    final isPassenger = p.role == ParticipantRole.passenger;
    final canEditVehicle = isDriver &&
        (p.status == ParticipantStatus.approved ||
            p.status == ParticipantStatus.confirmed ||
            p.status == ParticipantStatus.assigned);
    final canEditPickup = isPassenger &&
        (p.status == ParticipantStatus.requested ||
            p.status == ParticipantStatus.approved ||
            p.status == ParticipantStatus.confirmed);
    final canEditTripStart = isDriver &&
        (p.status == ParticipantStatus.requested ||
            p.status == ParticipantStatus.approved ||
            p.status == ParticipantStatus.confirmed);
    final hasPickup = p.pickupAddress != null && p.pickupAddress!.isNotEmpty;
    final hasTripStart = hasPickup;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              Chip(label: Text(participantRoleLabel(p.role))),
              Chip(label: Text(participantStatusLabel(p.status))),
            ]),
            if (isDriver) ...[
              const SizedBox(height: 12),
              _DriverVehicleRow(
                participant: p,
                onPick: _working ? null : _pickVehicle,
                canEdit: canEditVehicle,
              ),
              const SizedBox(height: 12),
              _DriverTripStartRow(
                participant: p,
                onEdit: _working ? null : _editTripStart,
                canEdit: canEditTripStart,
                hasTripStart: hasTripStart,
              ),
            ],
            if (isPassenger) ...[
              const SizedBox(height: 12),
              _PassengerPickupRow(
                participant: p,
                onEdit: _working ? null : _editPickup,
                canEdit: canEditPickup,
                hasPickup: hasPickup,
              ),
            ],
            if (!isOrganizerRow && p.status == ParticipantStatus.assigned)
              _MyTripLink(eventId: widget.eventId, participant: p),
            if (!isOrganizerRow) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (canConfirm)
                  FilledButton(
                    onPressed: _working
                        ? null
                        : () => _act(
                              () => api.confirm(widget.eventId, p.id).then((_) {}),
                              'Confirmed',
                            ),
                    child: const Text('Confirm'),
                  ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: _working
                        ? null
                        : () => _act(
                              () => api.cancel(widget.eventId, p.id).then((_) {}),
                              'Cancel my spot',
                            ),
                    child: const Text('Cancel my spot'),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders a "View your trip" button once the viewer has been assigned to
/// a trip in this event. Loads the event's trip list (organizer-or-participant
/// readable) and finds the trip belonging to the current user as driver or as
/// a stop participant.
class _EventTripsLink extends StatelessWidget {
  const _EventTripsLink({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('View event trips'),
            onPressed: () => context.push(RoutePaths.eventTripsFor(eventId)),
          ),
        ),
      ),
    );
  }
}

class _MyTripLink extends ConsumerWidget {
  const _MyTripLink({required this.eventId, required this.participant});
  final String eventId;
  final EventParticipantResponse participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(eventAssignmentPlanProvider(eventId));
    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) {
        TripResponse? mine;
        for (final trip in plan.trips) {
          if (trip.driverId == participant.userId) {
            mine = trip;
            break;
          }
          final hasStop = trip.stops.any((s) => s.userId == participant.userId);
          if (hasStop) {
            mine = trip;
            break;
          }
        }
        if (mine == null) return const SizedBox.shrink();
        final isDriver = mine.driverId == participant.userId;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.alt_route),
            label: Text(isDriver ? 'Open my driver trip' : 'Open my ride'),
            onPressed: () => context.push(
              isDriver
                  ? RoutePaths.driverTripFor(mine!.id)
                  : RoutePaths.passengerRideFor(mine!.id),
            ),
          ),
        );
      },
    );
  }
}

class _DriverVehicleRow extends StatelessWidget {
  const _DriverVehicleRow({
    required this.participant,
    required this.onPick,
    required this.canEdit,
  });

  final EventParticipantResponse participant;
  final VoidCallback? onPick;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final summary = participant.vehicleSummary;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary == null ? 'No vehicle selected' : summary.label,
                  style: theme.textTheme.bodyLarge,
                ),
                if (summary != null)
                  Text('${summary.seats} seats',
                      style: theme.textTheme.bodySmall),
                if (summary == null && canEdit)
                  Text(
                    'Required before the organizer can assign passengers',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          if (canEdit)
            TextButton(
              onPressed: onPick,
              child: Text(summary == null ? 'Choose' : 'Change'),
            ),
        ],
      ),
    );
  }
}

class _DriverTripStartRow extends StatelessWidget {
  const _DriverTripStartRow({
    required this.participant,
    required this.onEdit,
    required this.canEdit,
    required this.hasTripStart,
  });

  final EventParticipantResponse participant;
  final VoidCallback? onEdit;
  final bool canEdit;
  final bool hasTripStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.trip_origin),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTripStart
                      ? participant.pickupAddress!
                      : 'No trip start location',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  'Where you begin the pickup route',
                  style: theme.textTheme.bodySmall,
                ),
                if (!hasTripStart && canEdit)
                  Text(
                    'Recommended for better stop ordering during auto-assign',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          if (canEdit)
            TextButton(
              onPressed: onEdit,
              child: Text(hasTripStart ? 'Change' : 'Set'),
            ),
        ],
      ),
    );
  }
}

class _PassengerPickupRow extends StatelessWidget {
  const _PassengerPickupRow({
    required this.participant,
    required this.onEdit,
    required this.canEdit,
    required this.hasPickup,
  });

  final EventParticipantResponse participant;
  final VoidCallback? onEdit;
  final bool canEdit;
  final bool hasPickup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPickup ? participant.pickupAddress! : 'No pickup address',
                  style: theme.textTheme.bodyLarge,
                ),
                if (!hasPickup && canEdit)
                  Text(
                    'Required before the organizer can assign you to a ride',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          if (canEdit)
            TextButton(
              onPressed: onEdit,
              child: Text(hasPickup ? 'Change' : 'Add'),
            ),
        ],
      ),
    );
  }
}

class _OrganizerActions extends ConsumerStatefulWidget {
  const _OrganizerActions({required this.event});
  final EventResponse event;

  @override
  ConsumerState<_OrganizerActions> createState() => _OrganizerActionsState();
}

class _OrganizerActionsState extends ConsumerState<_OrganizerActions> {
  bool _working = false;

  Future<void> _act(Future<void> Function() action, String msg) async {
    setState(() => _working = true);
    try {
      await action();
      ref.invalidate(eventDetailProvider(widget.event.id));
      ref.invalidate(eventDashboardProvider(widget.event.id));
      ref.invalidate(myEventsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _autoAssign() async {
    if (_working || widget.event.planningStatus == 'IN_PROGRESS') return;
    setState(() => _working = true);
    try {
      final plan = await ref
          .read(assignmentApiProvider)
          .generateAssignments(widget.event.id);
      ref.invalidate(eventAssignmentPlanProvider(widget.event.id));
      ref.invalidate(eventParticipantsProvider(widget.event.id));
      ref.invalidate(eventDashboardProvider(widget.event.id));
      ref.invalidate(eventDetailProvider(widget.event.id));
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(plan.autoAssignSummaryMessage)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.read(eventApiProvider);
    final status = widget.event.status;
    final canClose = status == EventStatus.open;
    final canReopen = status == EventStatus.closed;
    final canCancel = status != EventStatus.completed && status != EventStatus.cancelled;
    final canDelete = status == EventStatus.cancelled || status == EventStatus.draft;

    // "Manage assignments" is always available to the organizer once the event
    // is in a planning-relevant state. We allow it for OPEN, CLOSED, and
    // IN_PROGRESS so plans can still be reshuffled mid-event if needed.
    final canManageAssignments = widget.event.status == EventStatus.open ||
        widget.event.status == EventStatus.closed ||
        widget.event.status == EventStatus.inProgress;

    if (!canClose &&
        !canReopen &&
        !canCancel &&
        !canDelete &&
        !canManageAssignments) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organizer actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (canManageAssignments) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.auto_mode),
                  label: const Text('Auto assign'),
                  onPressed: _working ||
                          widget.event.planningStatus == 'IN_PROGRESS'
                      ? null
                      : _autoAssign,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Manage assignments'),
                  onPressed: _working
                      ? null
                      : () => context.push(
                          RoutePaths.manageAssignmentsFor(widget.event.id)),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.monitor_heart_outlined),
                  label: const Text('Event trips'),
                  onPressed: _working
                      ? null
                      : () => context.push(
                          RoutePaths.eventTripsFor(widget.event.id)),
                ),
              ],
              if (canClose)
                OutlinedButton(
                  onPressed: _working
                      ? null
                      : () => _act(
                            () => api.close(widget.event.id).then((_) {}),
                            'Event closed',
                          ),
                  child: const Text('Close to new joiners'),
                ),
              if (canReopen)
                FilledButton(
                  onPressed: _working
                      ? null
                      : () => _act(
                            () => api.reopen(widget.event.id).then((_) {}),
                            'Event reopened',
                          ),
                  child: const Text('Reopen to new joiners'),
                ),
              if (canCancel)
                OutlinedButton(
                  onPressed: _working
                      ? null
                      : () => _act(
                            () => api.cancel(widget.event.id).then((_) {}),
                            'Event cancelled',
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Cancel event'),
                ),
              if (canDelete)
                FilledButton(
                  onPressed: _working ? null : () => _confirmDelete(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Delete event'),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text(
            'This permanently removes the event and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _working = true);
    try {
      await ref.read(eventApiProvider).delete(widget.event.id);
      ref.invalidate(myEventsProvider);
      ref.invalidate(organizerDashboardProvider);
      if (!context.mounted) return;
      context.go(RoutePaths.organizer);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (context.mounted) setState(() => _working = false);
    }
  }
}

class _ParticipantTile extends ConsumerStatefulWidget {
  const _ParticipantTile({
    required this.event,
    required this.participant,
    required this.isOrganizer,
    required this.currentUserId,
  });
  final EventResponse event;
  final EventParticipantResponse participant;
  final bool isOrganizer;
  final String currentUserId;

  @override
  ConsumerState<_ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends ConsumerState<_ParticipantTile> {
  bool _working = false;

  void _refreshAll() {
    ref.invalidate(eventParticipantsProvider(widget.event.id));
    ref.invalidate(eventDetailProvider(widget.event.id));
    ref.invalidate(eventDashboardProvider(widget.event.id));
  }

  Future<void> _act(Future<void> Function() action, String msg) async {
    setState(() => _working = true);
    try {
      await action();
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  static const _organizerEditableStatuses = {
    ParticipantStatus.ready,
    ParticipantStatus.requested,
    ParticipantStatus.approved,
    ParticipantStatus.confirmed,
  };

  Future<void> _edit() async {
    final saved = await showOrganizerParticipantEditSheet(
      context,
      eventId: widget.event.id,
      participant: widget.participant,
    );
    if (saved == true) _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final api = ref.read(participantApiProvider);
    final canApproveReject =
        widget.isOrganizer && p.status == ParticipantStatus.requested;
    final canRemove = widget.isOrganizer &&
        p.role != ParticipantRole.organizer &&
        (p.status == ParticipantStatus.approved ||
            p.status == ParticipantStatus.confirmed ||
            p.status == ParticipantStatus.ready);
    final canEdit = widget.isOrganizer &&
        p.role != ParticipantRole.organizer &&
        _organizerEditableStatuses.contains(p.status);
    final canRejoin = p.userId == widget.currentUserId &&
        p.status == ParticipantStatus.cancelled &&
        widget.event.status == EventStatus.open;
    final needsVehicle = p.role == ParticipantRole.driver &&
        p.vehicleSummary == null &&
        p.status != ParticipantStatus.cancelled;

    return Card(
      child: ListTile(
        title: Text(p.displayLabel.isEmpty ? p.userEmail : p.displayLabel),
        subtitle: Text(
          needsVehicle
              ? '${participantRoleLabel(p.role)} · ${participantStatusLabel(p.status)} · '
                  'Vehicle required before assignment'
              : '${participantRoleLabel(p.role)} · ${participantStatusLabel(p.status)}',
          style: needsVehicle
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        trailing: (!widget.isOrganizer && !canRejoin)
            ? null
            : Wrap(
                spacing: 4,
                children: [
                  if (canApproveReject)
                    IconButton(
                      tooltip: 'Approve',
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _working
                          ? null
                          : () => _act(
                                () => api.approve(widget.event.id, p.id).then((_) {}),
                                'Approved',
                              ),
                    ),
                  if (canApproveReject)
                    IconButton(
                      tooltip: 'Reject',
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _working
                          ? null
                          : () => _act(
                                () => api.reject(widget.event.id, p.id).then((_) {}),
                                'Rejected',
                              ),
                    ),
                  if (canEdit)
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _working ? null : _edit,
                    ),
                  if (canRemove)
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: _working
                          ? null
                          : () => _act(
                                () => api.remove(widget.event.id, p.id),
                                'Removed',
                              ),
                    ),
                  if (canRejoin)
                    TextButton.icon(
                      icon: const Icon(Icons.redo),
                      label: const Text('Request to rejoin'),
                      onPressed: _working
                          ? null
                          : () => _act(
                                () => api.rejoin(widget.event.id, p.id).then((_) {}),
                                'Rejoin request sent',
                              ),
                    ),
                ],
              ),
      ),
    );
  }
}
