/// Non-web platforms don't load the Maps JS SDK at all — Android/iOS get the
/// key natively (AndroidManifest.xml meta-data / Info.plist GMSApiKey).
Future<void> ensureGoogleMapsScriptLoaded() async {}
