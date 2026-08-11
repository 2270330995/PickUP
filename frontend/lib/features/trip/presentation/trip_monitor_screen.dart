import 'package:flutter/material.dart';

import 'trip_detail_screen.dart';

/// Read-only trip view for organizers monitoring execution progress.
class TripMonitorScreen extends StatelessWidget {
  const TripMonitorScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return TripDetailScreen(
      tripId: tripId,
      mode: TripViewMode.monitor,
      appBarTitle: 'Trip progress',
    );
  }
}
