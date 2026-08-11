import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../user/data/user_api.dart';
import '../data/trip_api.dart';
import '../data/trip_dtos.dart';

/// Lists the current user's trips — both ones they drive and ones in which they're a passenger.
/// Tapping routes to the appropriate driver or passenger view.
class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);
    final meAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My trips')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myTripsProvider),
        child: tripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load trips'),
            ],
          ),
          data: (trips) => meAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load profile')),
            data: (me) {
              if (trips.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 80),
                    Icon(Icons.alt_route_outlined, size: 56),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        "You don't have any trips yet.\n"
                        "Trips appear once an organizer assigns you.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (_, i) => _TripCard(
                  trip: trips[i],
                  isMyDriverTrip: trips[i].driverId == me.id,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.isMyDriverTrip});
  final TripResponse trip;
  final bool isMyDriverTrip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isMyDriverTrip ? Icons.directions_car : Icons.event_seat),
        ),
        title: Text(trip.eventTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.eventTime.toLocal().toString()),
            const SizedBox(height: 4),
            Wrap(spacing: 8, runSpacing: -4, children: [
              Chip(label: Text(isMyDriverTrip ? 'You drive' : 'You ride')),
              Chip(label: Text(tripStatusLabel(trip.status))),
              if (!isMyDriverTrip)
                Chip(label: Text('Driver: ${trip.driverFullName}')),
            ]),
          ],
        ),
        isThreeLine: true,
        onTap: () => context.push(
          isMyDriverTrip
              ? RoutePaths.driverTripFor(trip.id)
              : RoutePaths.passengerRideFor(trip.id),
        ),
      ),
    );
  }
}
