import 'package:flutter/material.dart';

import '../../trip/presentation/trip_detail_screen.dart';

/// Thin wrapper around [TripDetailScreen] in driver mode so the existing
/// /driver/trips/:tripId route keeps working.
class DriverTripScreen extends StatelessWidget {
  const DriverTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return TripDetailScreen(
      tripId: tripId,
      mode: TripViewMode.driver,
      appBarTitle: 'Driver trip',
    );
  }
}
