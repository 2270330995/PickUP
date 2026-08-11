import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../dashboard/data/dashboard_api.dart';
import '../../event/data/event_api.dart';
import '../../participant/data/participant_api.dart';
import '../../participant/data/participant_dtos.dart';
import '../../trip/data/trip_api.dart';
import '../../trip/data/trip_dtos.dart';
import '../../trip/presentation/ordered_stop_preview.dart';
import '../data/assignment_api.dart';
import '../data/assignment_dtos.dart';

/// Organizer-only screen: build the manual assignment plan for an event.
///
/// UX:
///   - One card per confirmed driver, with their vehicle + capacity + currently chosen passengers.
///   - Tap "Assign passengers" to multi-select from the pool of confirmed passengers
///     not yet placed on any other driver.
///   - "Save plan" submits the full-replace payload to the backend.
class ManageAssignmentsScreen extends ConsumerStatefulWidget {
  const ManageAssignmentsScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<ManageAssignmentsScreen> createState() =>
      _ManageAssignmentsScreenState();
}

class _ManageAssignmentsScreenState
    extends ConsumerState<ManageAssignmentsScreen> {
  /// Local working state: driverParticipantId -> ordered passengerParticipantIds
  Map<String, List<String>> _draft = {};

  /// Tracks the server plan version last used to populate [_draft].
  String? _draftSeedKey;
  bool _saving = false;
  bool _autoAssigning = false;

  static bool _isAssignable(EventParticipantResponse p) =>
      p.status == ParticipantStatus.confirmed ||
      p.status == ParticipantStatus.ready ||
      p.status == ParticipantStatus.assigned;

  List<EventParticipantResponse> _editableDrivers(
    List<EventParticipantResponse> participants,
    AssignmentPlanResponse plan,
  ) {
    return participants
        .where((p) =>
            p.role == ParticipantRole.driver &&
            _isAssignable(p) &&
            p.vehicleSummary != null &&
            _hasEditableTrip(p, plan))
        .toList();
  }

  String _planSeedKey(AssignmentPlanResponse plan) {
    final parts = <String>[];
    for (final trip in plan.trips) {
      if (trip.status != TripStatus.assigned) continue;
      parts.add(
        '${trip.id}:${trip.stops.map((s) => s.participantId).join(',')}',
      );
    }
    parts.sort();
    return parts.join('|');
  }

  Map<String, List<String>> _buildDraftFromPlan(
    List<EventParticipantResponse> editableDrivers,
    AssignmentPlanResponse plan,
  ) {
    final next = <String, List<String>>{};
    for (final d in editableDrivers) {
      next[d.id] = <String>[];
    }
    for (final trip in plan.trips) {
      if (trip.status != TripStatus.assigned) continue;
      final driverRow = editableDrivers
          .where((d) => _tripBelongsToDriver(trip, d))
          .cast<EventParticipantResponse?>()
          .firstOrNull;
      if (driverRow == null) continue;
      next[driverRow.id] = trip.stops
          .map((s) => s.participantId)
          .toList(growable: false);
    }
    return next;
  }

  void _applyDraftFromPlan(
    List<EventParticipantResponse> participants,
    AssignmentPlanResponse plan,
  ) {
    final editableDrivers = _editableDrivers(participants, plan);
    _draft = _buildDraftFromPlan(editableDrivers, plan);
    _draftSeedKey = _planSeedKey(plan);
  }

  void _maybeSyncDraftFromPlan(
    List<EventParticipantResponse> participants,
    AssignmentPlanResponse plan,
  ) {
    final seedKey = _planSeedKey(plan);
    if (_draftSeedKey == seedKey) return;
    // While providers refetch, ignore stale empty plans that would wipe local edits.
    if (_draftSeedKey != null &&
        seedKey.isEmpty &&
        _draft.values.any((passengers) => passengers.isNotEmpty)) {
      return;
    }
    _applyDraftFromPlan(participants, plan);
  }

  /// Matches a trip to a driver participant by `driverParticipantId` (the
  /// canonical link since Phase 4D-2), falling back to `driverId` for legacy
  /// trips created before then.
  bool _tripBelongsToDriver(TripResponse trip, EventParticipantResponse driver) {
    if (trip.driverParticipantId != null) {
      return trip.driverParticipantId == driver.id;
    }
    return driver.userId != null && trip.driverId == driver.userId;
  }

  bool _hasEditableTrip(EventParticipantResponse driver, AssignmentPlanResponse plan) {
    final trip = plan.trips
        .cast<TripResponse?>()
        .firstWhere((t) => t != null && _tripBelongsToDriver(t, driver), orElse: () => null);
    return trip == null || trip.status == TripStatus.assigned;
  }

  Set<String> get _assignedPassengerIds {
    final all = <String>{};
    for (final list in _draft.values) {
      all.addAll(list);
    }
    return all;
  }

  Future<void> _openPicker({
    required EventParticipantResponse driver,
    required List<EventParticipantResponse> allConfirmedPassengers,
  }) async {
    final currentList = _draft[driver.id] ?? const <String>[];
    final mySet = currentList.toSet();
    final globallyAssigned = _assignedPassengerIds.difference(mySet);
    final maxPassengers =
        ((driver.vehicleSummary?.seats ?? 1) - 1).clamp(0, 99);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _PassengerPickerSheet(
        driver: driver,
        allConfirmedPassengers: allConfirmedPassengers,
        initiallySelected: mySet,
        alreadyAssignedElsewhere: globallyAssigned,
        maxPassengers: maxPassengers,
      ),
    );
    if (result == null) return;
    setState(() {
      _draft[driver.id] = result;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = SubmitAssignmentsRequest(
        assignments: _draft.entries
            .map((e) => DriverAssignmentInput(
                  driverParticipantId: e.key,
                  passengerParticipantIds: List<String>.from(e.value),
                ))
            .toList(growable: false),
      );
      final savedPlan = await ref
          .read(assignmentApiProvider)
          .submit(widget.eventId, payload);
      ref.invalidate(eventParticipantsProvider(widget.eventId));
      ref.invalidate(eventAssignmentPlanProvider(widget.eventId));
      ref.invalidate(eventDashboardProvider(widget.eventId));
      ref.invalidate(eventDetailProvider(widget.eventId));
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      final participants =
          await ref.read(eventParticipantsProvider(widget.eventId).future);
      if (!mounted) return;
      setState(() => _applyDraftFromPlan(participants, savedPlan));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment plan saved')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _autoAssign() async {
    setState(() => _autoAssigning = true);
    try {
      final savedPlan = await ref
          .read(assignmentApiProvider)
          .generateAssignments(widget.eventId);
      ref.invalidate(eventParticipantsProvider(widget.eventId));
      ref.invalidate(eventAssignmentPlanProvider(widget.eventId));
      ref.invalidate(eventDashboardProvider(widget.eventId));
      ref.invalidate(eventDetailProvider(widget.eventId));
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      final participants =
          await ref.read(eventParticipantsProvider(widget.eventId).future);
      if (!mounted) return;
      setState(() => _applyDraftFromPlan(participants, savedPlan));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(savedPlan.autoAssignSummaryMessage)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _autoAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(eventParticipantsProvider(widget.eventId));
    final planAsync = ref.watch(eventAssignmentPlanProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Assign passengers')),
      body: RefreshIndicator(
        onRefresh: () async {
          _draftSeedKey = null;
          ref.invalidate(eventParticipantsProvider(widget.eventId));
          ref.invalidate(eventAssignmentPlanProvider(widget.eventId));
        },
        child: participantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load participants'),
            ],
          ),
          data: (participants) {
            return planAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(err is ApiException ? err.message : 'Failed to load plan'),
                ],
              ),
              data: (plan) => _buildBody(
                participants,
                plan,
                eventAsync.valueOrNull?.assignmentGenerated ?? false,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _autoAssigning || _saving ? null : _autoAssign,
                  child: _autoAssigning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Auto assign'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving || _autoAssigning || _draftSeedKey == null
                      ? null
                      : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    List<EventParticipantResponse> participants,
    AssignmentPlanResponse plan,
    bool assignmentGenerated,
  ) {
    final editableDrivers = _editableDrivers(participants, plan);
    final lockedTrips = plan.trips
        .where((t) => t.status != TripStatus.assigned)
        .toList(growable: false);
    final driversMissingVehicle = participants
        .where((p) =>
            p.role == ParticipantRole.driver &&
            _isAssignable(p) &&
            p.vehicleSummary == null)
        .toList();
    final passengers = participants
        .where((p) => p.role == ParticipantRole.passenger && _isAssignable(p))
        .toList();

    _maybeSyncDraftFromPlan(participants, plan);

    final assigned = _assignedPassengerIds;
    final unassigned =
        passengers.where((p) => !assigned.contains(p.id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (lockedTrips.isNotEmpty) ...[
          Text(
            'Active & completed trips (${lockedTrips.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...lockedTrips.map((t) => _LockedTripCard(trip: t)),
          const SizedBox(height: 24),
        ],
        if (driversMissingVehicle.isNotEmpty)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${driversMissingVehicle.length} driver(s) still need a vehicle '
                'before they can take passengers.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        if (editableDrivers.isEmpty && lockedTrips.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No drivers ready with a vehicle yet. '
              'Drivers must be ready/confirmed and have a vehicle before you can assign passengers.',
            ),
          )
        else if (editableDrivers.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan assignments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (assignmentGenerated)
                const Chip(
                  avatar: Icon(Icons.auto_mode, size: 16),
                  label: Text('Auto-assigned'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...editableDrivers.map((d) => _DriverCard(
                driver: d,
                selectedPassengerIds: _draft[d.id] ?? const <String>[],
                allParticipants: participants,
                onOpenPicker: () =>
                    _openPicker(driver: d, allConfirmedPassengers: passengers),
                onClear: () => setState(() => _draft[d.id] = const <String>[]),
              )),
        ],
        const SizedBox(height: 16),
        Text(
          'Unassigned passengers ready for a ride (${unassigned.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (passengers.isEmpty)
          const Text('No passengers ready for a ride yet.')
        else if (unassigned.isEmpty)
          const Text('All ready passengers are assigned to a driver.')
        else
          ...unassigned.map((p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(p.displayLabel.isEmpty ? p.userEmail : p.displayLabel),
                  subtitle: Text(
                    p.pickupAddress == null || p.pickupAddress!.isEmpty
                        ? 'No pickup address (can\'t assign)'
                        : p.pickupAddress!,
                  ),
                  trailing: (p.pickupAddress == null || p.pickupAddress!.isEmpty)
                      ? const Icon(Icons.error_outline, color: Colors.red)
                      : null,
                ),
              )),
      ],
    );
  }
}

class _LockedTripCard extends StatelessWidget {
  const _LockedTripCard({required this.trip});

  final TripResponse trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = trip.vehicleSummary;
    return Card(
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
                        trip.driverFullName.isEmpty ? 'Driver' : trip.driverFullName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(vehicle.label, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(label: Text(tripStatusLabel(trip.status))),
              ],
            ),
            const SizedBox(height: 12),
            OrderedStopPreview(stops: trip.stops),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.selectedPassengerIds,
    required this.allParticipants,
    required this.onOpenPicker,
    required this.onClear,
  });

  final EventParticipantResponse driver;
  final List<String> selectedPassengerIds;
  final List<EventParticipantResponse> allParticipants;
  final VoidCallback onOpenPicker;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final v = driver.vehicleSummary!;
    final maxPassengers = (v.seats - 1).clamp(0, 99);
    final over = selectedPassengerIds.length > maxPassengers;

    return Card(
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
                      Text(driver.displayLabel.isEmpty
                          ? driver.userEmail
                          : driver.displayLabel),
                      Text(v.label, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: over
                      ? Theme.of(context).colorScheme.errorContainer
                      : null,
                  label: Text(
                    '${selectedPassengerIds.length}/$maxPassengers seats',
                    style: TextStyle(
                      color: over
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OrderedParticipantStopPreview(
              orderedParticipantIds: selectedPassengerIds,
              allParticipants: allParticipants,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign passengers'),
                  onPressed: onOpenPicker,
                ),
                if (selectedPassengerIds.isNotEmpty)
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerPickerSheet extends StatefulWidget {
  const _PassengerPickerSheet({
    required this.driver,
    required this.allConfirmedPassengers,
    required this.initiallySelected,
    required this.alreadyAssignedElsewhere,
    required this.maxPassengers,
  });

  final EventParticipantResponse driver;
  final List<EventParticipantResponse> allConfirmedPassengers;
  final Set<String> initiallySelected;
  final Set<String> alreadyAssignedElsewhere;
  final int maxPassengers;

  @override
  State<_PassengerPickerSheet> createState() => _PassengerPickerSheetState();
}

class _PassengerPickerSheetState extends State<_PassengerPickerSheet> {
  late final List<String> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List<String>.from(widget.initiallySelected);
  }

  void _toggle(EventParticipantResponse p) {
    setState(() {
      if (_ordered.contains(p.id)) {
        _ordered.remove(p.id);
      } else {
        if (_ordered.length >= widget.maxPassengers) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vehicle full: max ${widget.maxPassengers} passengers',
              ),
            ),
          );
          return;
        }
        _ordered.add(p.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assign to ${widget.driver.displayLabel}',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '${_ordered.length}/${widget.maxPassengers} seats used',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allConfirmedPassengers.length,
                itemBuilder: (_, i) {
                  final p = widget.allConfirmedPassengers[i];
                  final isMine = _ordered.contains(p.id);
                  final isOnOtherDriver =
                      widget.alreadyAssignedElsewhere.contains(p.id);
                  final missingPickup =
                      p.pickupAddress == null || p.pickupAddress!.isEmpty;
                  final disabled = isOnOtherDriver || missingPickup;
                  return CheckboxListTile(
                    value: isMine,
                    enabled: !disabled,
                    onChanged: disabled ? null : (_) => _toggle(p),
                    title: Text(
                      p.displayLabel.isEmpty ? p.userEmail : p.displayLabel,
                    ),
                    subtitle: Text(
                      missingPickup
                          ? 'No pickup address'
                          : isOnOtherDriver
                              ? 'Already assigned to another driver'
                              : (p.pickupAddress ?? ''),
                      style: TextStyle(
                        color: disabled ? theme.colorScheme.error : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(List<String>.from(_ordered)),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
