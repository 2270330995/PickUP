# features/driver

Driver-mode view of a trip, for the legacy self-join flow where a driver is a
logged-in user (not an organizer-managed Contact). Contains presentation only
— no feature-specific data layer, since it reuses `features/trip/data`.

## Subdirectories

- [`presentation/`](presentation/README.md) — `DriverTripScreen`, a thin
  `TripViewMode.driver` wrapper around `TripDetailScreen`.

## How it connects

Routed at `/driver/trips/:tripId`. See
[`features/trip`](../trip/README.md) for the shared trip detail
implementation and [`features/passenger`](../passenger/README.md) for the
equivalent passenger-mode wrapper.
