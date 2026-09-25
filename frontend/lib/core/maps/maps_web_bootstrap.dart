import 'maps_web_bootstrap_stub.dart'
    if (dart.library.html) 'maps_web_bootstrap_web.dart' as impl;

/// On Flutter web, injects the Google Maps JavaScript API `<script>` tag
/// using the `GOOGLE_MAPS_API_KEY` passed via `--dart-define`, mirroring how
/// `GOOGLE_PLACES_API_KEY` is already supplied — so the key never has to be
/// hand-edited into web/index.html. A no-op on every other platform (Android
/// and iOS get the key natively instead; see .env.example).
///
/// Never throws: a missing key or failed script load just means the map
/// screen renders without tiles, not a broken app startup.
Future<void> ensureGoogleMapsScriptLoaded() => impl.ensureGoogleMapsScriptLoaded();
