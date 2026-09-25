// This file only ever compiles into the web target (selected via the
// conditional import in maps_web_bootstrap.dart), so dart:html here is the
// deliberate platform-specific implementation, not a cross-platform leak.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Pass via: flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=your-key
const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

const String _scriptId = 'google-maps-js-sdk';

Future<void> ensureGoogleMapsScriptLoaded() {
  // Hot restart re-runs main() without reloading the page, so the script
  // (and window.google) may already be there from a prior run.
  if (html.document.getElementById(_scriptId) != null) {
    return Future.value();
  }
  if (_apiKey.isEmpty) {
    // No key supplied — the map screen will render without tiles until one
    // is. Not fatal; nothing to inject.
    return Future.value();
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = _scriptId
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$_apiKey'
    ..defer = true;
  script.onLoad.first.then((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.first.then((_) {
    // Bad key / network failure — degrade to a tile-less map, don't block startup.
    if (!completer.isCompleted) completer.complete();
  });
  html.document.head!.append(script);
  return completer.future;
}
