# common/enums

The state machines and role/type vocabularies shared across the backend.

## What's in it

- `EventStatus` — event lifecycle: `DRAFT, OPEN, CLOSED, IN_PROGRESS, COMPLETED,
  CANCELLED`.
- `EventPlanningStatus` — auto-assignment progress, orthogonal to `EventStatus`:
  `NOT_STARTED, IN_PROGRESS, READY, FAILED`.
- `ParticipantRole` — per-event role: `ORGANIZER, DRIVER, PASSENGER,
  INDEPENDENT_ATTENDEE`.
- `ParticipantStatus` — the full `EventParticipantEntity` lifecycle: legacy
  self-join states (`INVITED, REQUESTED, APPROVED, REJECTED, CONFIRMED`) plus
  `READY` (organizer-added Contact-backed participants land here immediately —
  see the organizer-first model in the root `CLAUDE.md`), then
  `ASSIGNED, CHECKED_IN, PICKED_UP, ARRIVED, CANCELLED, NO_SHOW`. Not every
  transition is enforced yet; check the service before assuming one is wired up.
- `TripStatus` — `ASSIGNED, STARTED, IN_PROGRESS, WAITING_FOR_NEXT_STOP,
  ALL_PASSENGERS_PICKED, HEADING_TO_DESTINATION, COMPLETED, INTERRUPTED`. In
  practice `TripExecutionService` only drives `ASSIGNED -> IN_PROGRESS ->
  ALL_PASSENGERS_PICKED -> COMPLETED`; `STARTED`, `HEADING_TO_DESTINATION`, and
  `INTERRUPTED` are declared but unused so far.
- `StopStatus` — per-stop execution status: `PENDING, ACTIVE, NAVIGATING, ARRIVED,
  PICKED_UP, CANCELLED, SKIPPED`.
- `NavigationTargetType` — computed (not persisted) trip read-model field:
  `NONE, CURRENT_STOP, FINAL_DESTINATION`.
- `NotificationType` — `TRIP_ASSIGNED, PICKUP_INCOMING, EVENT_UPDATE, GENERIC`.
- `SystemRole` — global platform role (`USER, ADMIN`), deliberately separate from
  `ParticipantRole`.

## How it connects

These enums are the vocabulary every feature package (`event`, `participant`,
`trip`, `tripstop`, `notification`, `user`) builds its entities and state
transitions around. `AutoAssignmentService`/`AssignmentService` filter
participants by `ParticipantStatus`; `TripExecutionService` drives `TripStatus`
and `StopStatus`; `SecurityConfig`/`PickUpUserDetails` use `SystemRole` for Spring
Security authorities.
