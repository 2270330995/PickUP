import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user/data/user_api.dart';
import '../../trip/presentation/trip_detail_screen.dart';

/// Thin wrapper around [TripDetailScreen] in passenger mode. We thread the
/// current user id through so the shared widget can highlight the stop that
/// belongs to the viewer.
class PassengerRideScreen extends ConsumerWidget {
  const PassengerRideScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    return TripDetailScreen(
      tripId: tripId,
      mode: TripViewMode.passenger,
      currentUserId: me?.id,
      appBarTitle: 'My ride',
    );
  }
}
