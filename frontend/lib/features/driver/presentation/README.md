# features/driver/presentation

Driver-mode trip screen for a user-backed participant driving their own trip.

## Contents

- `driver_trip_screen.dart` — `DriverTripScreen(tripId)`: a thin wrapper
  rendering `TripDetailScreen` (`features/trip/presentation`) with
  `TripViewMode.driver` and app bar title "Driver trip". Kept as its own
  widget/file so the `/driver/trips/:tripId` route stays stable even though
  all the actual driver UI (stop list, navigation deep link, status
  transitions) lives in `TripDetailScreen`.

## How it connects

Routed at `RoutePaths.driverTrip` (`/driver/trips/:tripId`). Per the
organizer-first model, this only applies to self-join/legacy user-backed
drivers who can log in and execute their own trip — Contact-backed drivers
have no login, so their trips are monitored by the organizer via
`features/trip`'s monitor screen instead. See
[`../../trip/presentation/README.md`](../../trip/presentation/README.md) for
the shared trip-detail implementation.
