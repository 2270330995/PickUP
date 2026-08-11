import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an external app (e.g. Google Maps). Shows a SnackBar on failure.
Future<void> launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid navigation link')),
    );
    return;
  }

  try {
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation')),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open navigation')),
    );
  }
}
