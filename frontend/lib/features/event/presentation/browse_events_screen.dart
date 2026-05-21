import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../data/event_api.dart';
import '../data/event_dtos.dart';

class BrowseEventsScreen extends ConsumerWidget {
  const BrowseEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(openEventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Browse events')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(openEventsProvider),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load events'),
            ],
          ),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  Center(child: Text('No open events available to join right now.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _EventTile(event: events[i]),
            );
          },
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.destinationAddress),
            const SizedBox(height: 4),
            Text(
              '${event.eventTime.toLocal()} · organizer: ${event.organizerName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Chip(label: Text('${event.participantCount} joined')),
        onTap: () => context.push(RoutePaths.eventDetailFor(event.id)),
      ),
    );
  }
}
