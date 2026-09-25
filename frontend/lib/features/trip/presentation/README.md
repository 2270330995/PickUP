# features/trip/presentation

All trip-viewing screens, built around one shared, mode-driven widget
(`TripDetailScreen`) plus list screens and reusable stop-preview widgets.

## Contents

- `trip_detail_screen.dart` — `TripDetailScreen(tripId, mode, ...)` and
  `TripViewMode` (`driver`, `passenger`, `monitor`). The single implementation
  behind `features/driver`, `features/passenger`, and
  `features/trip/presentation/trip_monitor_screen.dart`:
  - `driver` mode shows the full execution flow: start-trip card (status
    `ASSIGNED`), navigation deep-link card (`core/launch`, when
    `trip.hasNavigation`), the current-active-stop card with Picked
    up/Skip/Cancel actions (`TripApi.updateStop`), and a complete-trip card
    once `ALL_PASSENGERS_PICKED`.
  - `passenger` mode shows a status card (`_PassengerRideStatusCard`)
    summarizing the viewer's own ride state in plain language, plus a
    read-only stop list with the viewer's own stop highlighted (matched by
    `currentUserId`).
  - `monitor` mode (organizer) is read-only: header, stop list, no execution
    actions.
  - Every mutating action invalidates `tripDetailProvider`,
    `myTripsProvider`, and `eventAssignmentPlanProvider` for that trip's
    event.
- `trip_monitor_screen.dart` — `TripMonitorScreen`, a thin
  `TripViewMode.monitor` wrapper.
- `event_trips_screen.dart` — `EventTripsScreen(eventId)`: read-only list of
  every trip in an event (via `eventAssignmentPlanProvider`,
  `features/assignment/data`) for organizers/participants to monitor
  execution progress; pull-to-refresh only (no live WebSocket updates yet,
  per an inline TODO comment).
- `my_trips_screen.dart` — `MyTripsScreen`: the viewer's own trips
  (`myTripsProvider`), tapping through to driver or passenger view depending
  on whether `trip.driverId == currentUser.id`.
- `ordered_stop_preview.dart` — `OrderedStopPreview` (from
  `TripStopSummary`s) and `OrderedParticipantStopPreview` (from a draft list
  of participant ids, for pre-save organizer editing): compact numbered
  pickup-order lists with ETA, reused by `features/assignment/presentation`
  and `event_trips_screen.dart`.

## How it connects

Built on `features/trip/data` (`TripApi`, DTOs) and
`features/assignment/data` (`eventAssignmentPlanProvider`, for
cross-invalidation and the event-trips list). Uses `core/format` for ETA
strings and `core/launch` for the navigation deep link. Routed at
`RoutePaths.myTrips`, `eventTrips`, `tripMonitor`; also rendered indirectly
via `RoutePaths.driverTrip`/`passengerRide` through
[`features/driver`](../../driver/README.md)/[`features/passenger`](../../passenger/README.md).
