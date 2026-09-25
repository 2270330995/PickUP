# features/location/data

Client for Google Places API (New) autocomplete/details, plus the shared
`ResolvedAddress` value type used anywhere the app captures an address +
coordinates.

## Contents

- `places_config.dart` — `googlePlacesApiKey` (from
  `--dart-define=GOOGLE_PLACES_API_KEY=...`) and
  `isGooglePlacesConfigured`. When no key is configured, autocomplete is
  disabled and callers fall back to manual lat/lng entry.
- `resolved_address.dart` — `ResolvedAddress {formattedAddress, lat, lng}`,
  the common shape passed between address pickers and every feature that
  needs a geocoded location (events, participant pickup, etc.).
- `places_api.dart`
  - `PlacesApi.autocomplete({input, sessionToken})` — calls Google's
    `places:autocomplete` directly from the client (not proxied through the
    backend) and maps predictions to `PlaceSuggestion {placeId, label}`.
  - `PlacesApi.resolveSuggestion({suggestion, sessionToken})` — resolves a
    suggestion to full `ResolvedAddress`. On Flutter web this is proxied
    through the backend's `POST /places/resolve` (browser CORS blocks the
    Place Details field-mask headers needed for a direct call); elsewhere it
    calls Google's Place Details endpoint directly, falling back to a
    `places:searchText` lookup if Place Details fails.
  - `placesApiProvider` — `Provider<PlacesApi>`, wiring the backend `Dio`
    (`dioProvider`) in as the web fallback path.

## How it connects

The only feature-data package that talks to a third-party API (Google
Places) directly rather than exclusively through the PickUp backend; the web
fallback path is the one place it does go through the backend
(`/api/v1/places/resolve`). Consumed by
`features/location/presentation/address_autocomplete_field.dart`.
