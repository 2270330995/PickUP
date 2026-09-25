# trip

Trip entity and the driver-facing execution lifecycle: starting a trip, resolving
stops one at a time, and completing it.

## What's in it

- `TripEntity` — `event`, `driver` (nullable `UserEntity` — null for
  Contact-backed drivers, who have no login), `driverParticipant` (the driver's
  `EventParticipantEntity`; always set for trips created since Phase 4D-2),
  `vehicle`, `status` (`TripStatus`), `currentStop` (drives the step-by-step UI,
  null until started), a snapshot of the event's final destination, an
  `encodedPolyline` placeholder, `startedAt`/`completedAt`, and the ordered
  `stops` list (`CascadeType.ALL`, `orphanRemoval = true`).
- `TripRepository` — lookups by event/driver, `existsByVehicleId` (used by
  `vehicle/VehicleService` to block seat changes/deletion on a referenced
  vehicle).
- `TripMapper` — entity -> `TripResponse`, resolving `driverFullName` from
  either the `UserEntity` or `ParticipantDisplayResolver` and delegating to
  `TripNavigationResolver` for the navigation fields.
- `TripService` — reads only: `getTrip` (authorized: organizer, driver, or a
  stop's participant), `listMyTrips` (trips driven + trips where the caller is a
  passenger, deduped, newest-first), `canView`.
- `TripExecutionService` — owns all trip-status mutation. Status model actually
  driven: `ASSIGNED -> IN_PROGRESS -> ALL_PASSENGERS_PICKED -> COMPLETED`
  (`STARTED`, `HEADING_TO_DESTINATION`, `INTERRUPTED` are declared in
  `TripStatus` but unused here).
  - `start` — `ASSIGNED -> IN_PROGRESS`, activates the first `PENDING` stop by
    sequence, stamps `startedAt`.
  - `updateStop` — only the trip's single `currentStop` may be resolved;
    `PICK_UP`/`SKIP`/`CANCEL` map to stop statuses `PICKED_UP`/`SKIPPED`/
    `CANCELLED`, mirrored onto the passenger's `ParticipantStatus`
    (`PICKED_UP`/`NO_SHOW`/`CANCELLED`); then activates the next `PENDING` stop
    or promotes the trip to `ALL_PASSENGERS_PICKED` if none remain.
  - `complete` — only from `ALL_PASSENGERS_PICKED` (defensively normalizes a
    stranded `IN_PROGRESS` trip with no remaining pending/active stops first);
    picked-up passengers and the driver move to `ARRIVED`.
  - `requireDriver` — Contact-backed drivers have no `UserEntity`, so trips
    without a user driver reject every execution call (organizer monitors those
    trips instead — see the root `CLAUDE.md`'s organizer-first model note on
    Contact-only drivers).
- `TripController` — `GET /events/{eventId}/trips` (delegates to
  `event/assignment/AssignmentService.getPlan`), `GET /trips/{tripId}`,
  `POST /trips/{tripId}/start`, `POST /trips/{tripId}/complete`,
  `PATCH /trips/{tripId}/stops/{stopId}`.
- [`dto/`](dto/README.md) — request/response records.
- [`navigation/`](navigation/README.md) — external nav-link derivation.
- [`planning/`](planning/README.md) — post-assignment ETA enrichment.

## How it connects

- Trips are only ever created by `event/assignment/AssignmentService.submit`
  (called from both manual assignment and `event/planning/AutoAssignmentService`)
  — this package never builds a `TripEntity` itself.
  `event/assignment/AssignmentPreservation` decides which `TripStatus` values
  block a trip from being rebuilt on resubmit.
  `trip/planning/TripRouteEnrichmentService` populates ETAs right after
  creation.
- Depends on `tripstop/` for `TripStopEntity`/`TripStopMapper`,
  `participant/` for `EventParticipantEntity`/`ParticipantDisplayResolver`, and
  `vehicle/`/`event/` for the referenced vehicle/event.
- `user/UserController` exposes `GET /users/me/trips` via `TripService.listMyTrips`.
