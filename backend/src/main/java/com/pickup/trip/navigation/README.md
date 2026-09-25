# trip/navigation

Computes the driver's step-by-step external navigation target and builds the
Google Maps deep link for it. Read-time derivation only — nothing here is
persisted.

## What's in it

- `GoogleMapsNavigationUrlBuilder` — `buildDrivingUrl(lat, lng)` returns an HTTPS
  `google.com/maps/dir/?api=1&destination=...&travelmode=driving` link (opens the
  native app on mobile when available), or `null` if the coordinate is invalid.
  `isValidCoordinate` is the canonical WGS-84 bounds check
  (`-90..90` / `-180..180`, finite) — reused by `common.geo.GeoLocationValidator`
  rather than duplicated there.
- `TripNavigationResolver` — `resolve(trip)`: while `IN_PROGRESS`, targets the
  trip's `currentStop` (`CURRENT_STOP`, label `"Pickup: <name>"`); once
  `ALL_PASSENGERS_PICKED`, targets the final destination (`FINAL_DESTINATION`,
  label `"Final destination"`); any other status yields `NavigationInfo.none()`
  (`NavigationTargetType.NONE`).

## How it connects

`TripMapper` calls `TripNavigationResolver.resolve` for every `TripResponse`,
populating `navigationTargetType`/`navigationLabel`/`navigationUrl`. Depends on
`common.enums.NavigationTargetType`/`TripStatus` and
`participant.ParticipantDisplayResolver` (for the stop label).
`common.geo.GeoLocationValidator.isValidCoordinate` delegates to this package's
`GoogleMapsNavigationUrlBuilder.isValidCoordinate` — a deliberate cross-package
dependency to keep coordinate-bounds logic in one place.
