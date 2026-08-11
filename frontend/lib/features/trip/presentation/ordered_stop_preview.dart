import 'package:flutter/material.dart';

import '../../../core/format/eta_format.dart';
import '../../participant/data/participant_dtos.dart';
import '../data/trip_dtos.dart';

/// Compact numbered pickup-stop list for organizer planning views.
class OrderedStopPreview extends StatelessWidget {
  const OrderedStopPreview({
    super.key,
    required this.stops,
    this.emptyLabel = 'No passengers assigned yet.',
  });

  final List<TripStopSummary> stops;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Text(emptyLabel);
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stops.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                child: Text(
                  '${stops[i].sequence + 1}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _stopLabel(stops[i]),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _stopLabel(TripStopSummary stop) {
    final name = stop.userFullName.trim();
    final eta = formatEtaMinutesShort(stop.etaMinutes);
    String base;
    if (name.isEmpty) {
      base = stop.address;
    } else if (stop.address.isEmpty) {
      base = name;
    } else {
      base = '$name — ${stop.address}';
    }
    if (eta == null) return base;
    return '$base ($eta)';
  }
}

/// Numbered preview from draft passenger IDs (pre-save organizer editing).
class OrderedParticipantStopPreview extends StatelessWidget {
  const OrderedParticipantStopPreview({
    super.key,
    required this.orderedParticipantIds,
    required this.allParticipants,
    this.emptyLabel = 'No passengers assigned yet.',
  });

  final List<String> orderedParticipantIds;
  final List<EventParticipantResponse> allParticipants;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (orderedParticipantIds.isEmpty) {
      return Text(emptyLabel);
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < orderedParticipantIds.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                child: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _labelForId(orderedParticipantIds[i]),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _labelForId(String participantId) {
    for (final p in allParticipants) {
      if (p.id == participantId) {
        final name = p.userFullName.trim();
        final displayName = name.isNotEmpty ? name : p.userEmail;
        final address = p.pickupAddress ?? '';
        if (address.isEmpty) {
          return displayName;
        }
        return '$displayName — $address';
      }
    }
    return participantId;
  }
}
