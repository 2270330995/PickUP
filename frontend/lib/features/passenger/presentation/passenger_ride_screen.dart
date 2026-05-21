import 'package:flutter/material.dart';

class PassengerRideScreen extends StatelessWidget {
  const PassengerRideScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My ride')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Trip ID: $tripId', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Live pickup tracking will subscribe to /topic/trips/{tripId} in Phase 2.'),
          ],
        ),
      ),
    );
  }
}
