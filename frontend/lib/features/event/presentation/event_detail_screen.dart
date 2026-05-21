import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../dashboard/data/dashboard_api.dart';
import '../../dashboard/data/dashboard_dtos.dart';
import '../../participant/data/participant_api.dart';
import '../../participant/data/participant_dtos.dart';
import '../../user/data/user_api.dart';
import '../data/event_api.dart';
import '../data/event_dtos.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
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
            _Header(event: event),
            const SizedBox(height: 16),
            dashboardAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (d) => _DashboardCard(data: d),
            ),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasJoined && event.status == EventStatus.open)
                      _JoinCard(eventId: event.id),
                    if (hasJoined)
                      _MyParticipationCard(eventId: event.id, participant: myParticipant),
                    const SizedBox(height: 16),
                    if (isOrganizer) _OrganizerActions(event: event),
                    const SizedBox(height: 24),
                    Text('Participants', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...participants.map((p) => _ParticipantTile(
                          event: event,
                          participant: p,
                          isOrganizer: isOrganizer,
                        )),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  EventParticipantResponse _emptyParticipant() {
    return EventParticipantResponse(
      id: '',
      eventId: event.id,
      userId: '',
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

class _Header extends StatelessWidget {
  const _Header({required this.event});
  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
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

  Future<void> _join() async {
    setState(() => _submitting = true);
    try {
      await ref.read(participantApiProvider).selfJoin(
            widget.eventId,
            JoinEventRequest(role: _role),
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

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final api = ref.read(participantApiProvider);
    final canConfirm = p.status == ParticipantStatus.approved;
    final canCancel = p.status == ParticipantStatus.requested ||
        p.status == ParticipantStatus.approved ||
        p.status == ParticipantStatus.confirmed;
    final isOrganizerRow = p.role == ParticipantRole.organizer;

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
            if (!isOrganizerRow) ...[
              const SizedBox(height: 12),
              Row(children: [
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
                if (canConfirm && canCancel) const SizedBox(width: 8),
                if (canCancel)
                  OutlinedButton(
                    onPressed: _working
                        ? null
                        : () => _act(
                              () => api.cancel(widget.eventId, p.id).then((_) {}),
                              'Cancelled',
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

  @override
  Widget build(BuildContext context) {
    final api = ref.read(eventApiProvider);
    final status = widget.event.status;
    final canClose = status == EventStatus.open;
    final canCancel = status != EventStatus.completed && status != EventStatus.cancelled;

    if (!canClose && !canCancel) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organizer actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
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
            ]),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends ConsumerStatefulWidget {
  const _ParticipantTile({
    required this.event,
    required this.participant,
    required this.isOrganizer,
  });
  final EventResponse event;
  final EventParticipantResponse participant;
  final bool isOrganizer;

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

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final api = ref.read(participantApiProvider);
    final canApproveReject =
        widget.isOrganizer && p.status == ParticipantStatus.requested;
    final canRemove = widget.isOrganizer && p.role != ParticipantRole.organizer;

    return Card(
      child: ListTile(
        title: Text(p.userFullName.isEmpty ? p.userEmail : p.userFullName),
        subtitle: Text(
          '${participantRoleLabel(p.role)} · ${participantStatusLabel(p.status)}',
        ),
        trailing: !widget.isOrganizer
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
                ],
              ),
      ),
    );
  }
}
