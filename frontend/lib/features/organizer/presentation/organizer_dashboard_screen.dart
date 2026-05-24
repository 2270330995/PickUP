import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../dashboard/data/dashboard_api.dart';
import '../../dashboard/data/dashboard_dtos.dart';
import '../../event/data/event_api.dart';
import '../../event/data/event_dtos.dart';
import '../../participant/data/participant_dtos.dart';

class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(organizerDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Up!'),
        actions: [
          IconButton(
            tooltip: 'Browse events',
            icon: const Icon(Icons.travel_explore),
            onPressed: () => context.push(RoutePaths.browseEvents),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(RoutePaths.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(organizerDashboardProvider);
          ref.invalidate(joinedEventsProvider);
        },
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load dashboard'),
            ],
          ),
          data: (data) => _DashboardBody(data: data),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.createEvent),
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});
  final OrganizerDashboardResponse data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedAsync = ref.watch(joinedEventsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Total events', value: '${data.totalEvents}')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Active events', value: '${data.activeEvents}')),
          ],
        ),
        const SizedBox(height: 24),
        Text('My events', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (data.events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No events yet. Create one!')),
          )
        else
          ...data.events.map((e) => _EventSummaryCard(summary: e)),
        const SizedBox(height: 24),
        Text('Events I\'ve joined', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        joinedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Could not load joined events'),
          data: (events) {
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('You haven\'t joined any events yet.')),
              );
            }
            return Column(
              children: events.map((e) => _JoinedEventCard(event: e)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

class _EventSummaryCard extends StatelessWidget {
  const _EventSummaryCard({required this.summary});
  final EventDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(summary.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.eventTime.toLocal().toString()),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: -4,
              children: [
                Chip(label: Text(eventStatusLabel(summary.status))),
                Chip(label: Text('${summary.totalParticipants} participants')),
                Chip(label: Text('${summary.confirmedDrivers} drivers')),
                if (summary.pendingRequests > 0)
                  Chip(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    label: Text('${summary.pendingRequests} pending'),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => context.go(RoutePaths.eventDetailFor(summary.eventId)),
      ),
    );
  }
}

class _JoinedEventCard extends StatelessWidget {
  const _JoinedEventCard({required this.event});
  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myStatus = event.currentUserParticipantStatus;
    final myRole = event.currentUserParticipantRole;
    final showRoleChip = myRole != null &&
        myRole != ParticipantRole.unknown &&
        myRole != ParticipantRole.organizer;
    final showStatusChip = myStatus != null && myStatus != ParticipantStatus.unknown;
    final statusColors = _statusColors(theme, myStatus);

    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.destinationAddress),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: -4,
              children: [
                if (showStatusChip)
                  Chip(
                    backgroundColor: statusColors.background,
                    label: Text(
                      'You: ${participantStatusLabel(myStatus)}',
                      style: TextStyle(color: statusColors.foreground),
                    ),
                  ),
                if (showRoleChip)
                  Chip(label: Text(participantRoleLabel(myRole))),
                Chip(label: Text(eventStatusLabel(event.status))),
                Chip(label: Text('Organizer: ${event.organizerName}')),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => context.go(RoutePaths.eventDetailFor(event.id)),
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});
  final Color? background;
  final Color? foreground;
}

_StatusColors _statusColors(ThemeData theme, ParticipantStatus? status) {
  final scheme = theme.colorScheme;
  switch (status) {
    case ParticipantStatus.confirmed:
    case ParticipantStatus.checkedIn:
    case ParticipantStatus.pickedUp:
    case ParticipantStatus.arrived:
      return _StatusColors(
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    case ParticipantStatus.approved:
    case ParticipantStatus.assigned:
      return _StatusColors(
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      );
    case ParticipantStatus.requested:
    case ParticipantStatus.invited:
      return _StatusColors(
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    case ParticipantStatus.rejected:
    case ParticipantStatus.cancelled:
    case ParticipantStatus.noShow:
      return _StatusColors(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    case ParticipantStatus.unknown:
    case null:
      return const _StatusColors(background: null, foreground: null);
  }
}
