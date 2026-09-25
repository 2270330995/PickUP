# features/trip

Trips: the output of auto-assignment/manual planning, each with a driver,
vehicle, and an ordered list of pickup stops, plus the driver's execution
lifecycle (start, resolve each stop, complete).

## Subdirectories

- [`data/`](data/README.md) — `TripApi` and the `TripResponse`/
  `TripStopSummary` read model plus `UpdateTripStopRequest` write DTO.
- [`presentation/`](presentation/README.md) — `TripDetailScreen` (the shared
  driver/passenger/monitor widget), `TripMonitorScreen`, `EventTripsScreen`,
  `MyTripsScreen`, and the `OrderedStopPreview` widgets.

## How it connects

Downstream of [`features/assignment`](../assignment/README.md) (trips are
created by `AssignmentApi.submit`/`generateAssignments`). Rendered in
driver/passenger mode via the thin wrappers in
[`features/driver`](../driver/README.md) and
[`features/passenger`](../passenger/README.md). Per the organizer-first
model, only legacy user-backed drivers execute their own trip through the
app — Contact-backed drivers' trips are organizer-monitored via
`TripMonitorScreen`/`EventTripsScreen`.
