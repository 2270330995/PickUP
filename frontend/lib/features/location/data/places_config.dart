/// Google Places API key for autocomplete and place details.
///
/// Pass at build/run time:
///   flutter run --dart-define=GOOGLE_PLACES_API_KEY=your-key
const String googlePlacesApiKey = String.fromEnvironment(
  'GOOGLE_PLACES_API_KEY',
  defaultValue: '',
);

bool get isGooglePlacesConfigured => googlePlacesApiKey.isNotEmpty;
