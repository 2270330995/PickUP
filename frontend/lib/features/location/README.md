# features/location

Address geocoding: Google Places autocomplete plus the reusable form widgets
and bottom sheets that capture a `ResolvedAddress` (formatted address + lat/
lng) anywhere in the app.

## Subdirectories

- [`data/`](data/README.md) — `PlacesApi`, `ResolvedAddress`, Places API key
  config.
- [`presentation/`](presentation/README.md) — `AddressAutocompleteField`,
  `showLocationPickerSheet`.

## How it connects

Consumed by `features/event` (destination), `features/participant`
(pickup/trip-start addresses), and anywhere else an address must be captured
with coordinates for the backend's geo/routing pipeline
(`RouteEstimateService`, per the repo's `CLAUDE.md`).
