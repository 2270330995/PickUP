# common/geo

Coordinate types and validation shared by every feature that stores or compares
lat/lng pairs.

## What's in it

- `GeoPoint` — a `(lat, lng)` record with two factory helpers:
  `tripStartFromDriver(EventParticipantEntity)` (a `DRIVER`'s `pickupLat/Lng` is
  interpreted as their trip-start anchor) and
  `pickupFromPassenger(EventParticipantEntity)`. Both return `Optional.empty()`
  when the coordinate is missing.
- `DistanceCalculator` — static Haversine great-circle distance in meters, no
  external calls. The deterministic fallback distance used everywhere before
  routing.
- `GeoLocationValidator` — the one place address/lat/lng triples are validated:
  `isValidCoordinate`, `validateCoordinateRange` (throws `BadRequestException`),
  `isComplete` (all three present and valid), `requireComplete` (throws if not),
  `requireCompleteOrAbsent` (all-or-nothing — used for optional location fields
  like a Contact's default address).
- `MeetingPointDefaults` — placeholder; `defaultName` always returns
  `Optional.empty()` today (meeting-point recommendation is unbuilt).

## How it connects

- `GeoLocationValidator` is called from `event/EventService` (destination),
  `contact/ContactService` (default location),
  `participant/EventParticipantService` (pickup / trip-start / organizer edits),
  and `event/assignment/AssignmentService` (passenger pickup completeness).
- `GeoPoint`/`DistanceCalculator` back
  [`common/geo/routing`](routing/README.md), which layers real-routing estimates
  on top.
- `GeoLocationValidator.isValidCoordinate` actually delegates to
  `trip/navigation/GoogleMapsNavigationUrlBuilder.isValidCoordinate` — a
  cross-package dependency to keep coordinate-bounds logic in one place.
