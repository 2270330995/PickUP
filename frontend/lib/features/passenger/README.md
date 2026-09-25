# features/passenger

Passenger-mode view of a trip, for a user-backed participant tracking their
ride. Contains presentation only — no feature-specific data layer, since it
reuses `features/trip/data`.

## Subdirectories

- [`presentation/`](presentation/README.md) — `PassengerRideScreen`, a thin
  `TripViewMode.passenger` wrapper around `TripDetailScreen`.

## How it connects

Routed at `/passenger/rides/:tripId`. See [`features/trip`](../trip/README.md)
for the shared trip detail implementation.
