import 'package:flutter/material.dart';

class DriverTripScreen extends StatelessWidget {
  const DriverTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Trip ID: $tripId', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Step-by-step navigation lands in Phase 3 (Google Maps deep links).'),
          ],
        ),
      ),
    );
  }
}
