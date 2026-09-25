# event/assignment

Persistence layer for both manual and auto-generated assignment plans: turns a
driver/passenger plan into `TripEntity` + `TripStopEntity` rows, atomically.

## What's in it

- `AssignmentService` — the only place trips are created or replaced.
  `submit(organizerId, eventId, request)`:
  1. Loads all event participants and indexes them by id.
  2. Computes `AssignmentPreservation.lockedDriverParticipantIds` so drivers on
     in-flight/completed trips are skipped even if resubmitted.
  3. Validates every `DriverAssignment` in the request: driver exists, role is
     `DRIVER`, status is assignable (`CONFIRMED`/`READY`/`ASSIGNED`), has a
     vehicle, isn't duplicated; each passenger exists, role is `PASSENGER`,
     status is assignable, has a complete pickup location, isn't double-booked;
     passenger count fits `seats - 1`.
  4. Deletes all prior *replaceable* trips (preserved ones are left alone),
     reverting their driver/passengers off `ASSIGNED` via
     `ParticipantDisplayResolver.priorAssignableStatus`, then flushes before
     inserting so the `(trip_id, sequence)` unique index never collides.
  5. Builds fresh `TripEntity`/`TripStopEntity` rows in the submitted order,
     enriches them via `TripRouteEnrichmentService`, and bumps placed
     participants to `ASSIGNED`.
  - `getPlan(eventId, viewerId)` — read-only, authorized for the organizer or any
    confirmed/assigned participant.
- `AssignmentPreservation` — shared rules for what must survive a resubmit:
  `PRESERVED_TRIP_STATUSES` (anything past `ASSIGNED` — `STARTED` through
  `COMPLETED`/`INTERRUPTED`), plus helpers to compute the locked driver/passenger
  participant ID sets from a trip list.
- `AssignmentController` — `POST /api/v1/events/{eventId}/assignments` (organizer
  only).
- [`dto/`](dto/README.md) — request/response records.

## How it connects

- Called directly by `AssignmentController` (manual assignment) and by
  `event/planning/AutoAssignmentService.generate` (auto-assignment) — both paths
  go through the same `submit` method, so manual and automatic plans obey
  identical validation/preservation rules.
- Depends on `event/EventService` (organizer check, event load),
  `participant/EventParticipantRepository` and `ParticipantDisplayResolver`,
  `trip/` (`TripEntity`, `TripRepository`, `TripMapper`),
  `trip/planning/TripRouteEnrichmentService`, and `tripstop/TripStopEntity`.
  Participates in the `ParticipantStatus`/`TripStatus`/`StopStatus` state
  machines from `common/enums`.
