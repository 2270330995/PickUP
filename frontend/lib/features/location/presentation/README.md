# features/location/presentation

Reusable address-entry widgets built on Google Places autocomplete, with a
manual lat/lng fallback when no API key is configured.

## Contents

- `address_autocomplete_field.dart` — `AddressAutocompleteField`, a
  `FormField<ResolvedAddress>`:
  - Debounces (350ms) text input, calls `PlacesApi.autocomplete`, and shows a
    suggestion dropdown; selecting one calls `PlacesApi.resolveSuggestion`
    and commits the resolved `ResolvedAddress` as the field's value.
  - Uses a per-field UUID session token (rotated after each resolve) as
    Google's Places API session-token billing model expects.
  - When `isGooglePlacesConfigured` is false, switches to "manual mode":
    plain address/latitude/longitude text fields with range validation
    (-90..90 / -180..180) instead of a search box.
  - In `kDebugMode`, shows the resolved lat/lng under the field for
    debugging.
- `location_picker_sheet.dart` — `showLocationPickerSheet(...)`: wraps
  `AddressAutocompleteField` in a modal bottom sheet with title/subtitle and
  a confirm button, returning the picked `ResolvedAddress?` (or `null` if
  cancelled).

## How it connects

Used anywhere an address needs to be captured: event destination
(`features/event/presentation/create_event_screen.dart`,
`event_detail_screen.dart`'s destination editor), participant pickup/trip-
start (`features/event/presentation`, `features/participant/presentation`).
Depends on `features/location/data` for the actual Places calls. See
[`../data/README.md`](../data/README.md).
