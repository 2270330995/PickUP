import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/maps/maps_web_bootstrap.dart';

Future<void> main() async {
  await ensureGoogleMapsScriptLoaded();
  runApp(const ProviderScope(child: PickUpApp()));
}
