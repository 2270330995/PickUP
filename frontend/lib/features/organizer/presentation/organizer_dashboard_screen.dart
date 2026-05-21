import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../dashboard/data/dashboard_api.dart';
import '../../dashboard/data/dashboard_dtos.dart';
import '../../event/data/event_dtos.dart';

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
        onRefresh: () async => ref.invalidate(organizerDashboardProvider),
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});
  final OrganizerDashboardResponse data;

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No events yet. Create one!')),
          )
        else
          ...data.events.map((e) => _EventSummaryCard(summary: e)),
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
        onTap: () => context.push(RoutePaths.eventDetailFor(summary.eventId)),
      ),
    );
  }
}
