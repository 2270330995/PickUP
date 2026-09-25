# participant

An event's roster: `EventParticipantEntity` rows that are either legacy
user-backed self-joins or organizer-added Contact-backed rows. This is the core
of the organizer-first model described in the root `CLAUDE.md` — read that
section first.

## What's in it

- `EventParticipantEntity` — `event`, exactly one of `user` (legacy) or
  `contact` (Phase 4D-2+, enforced by DB constraint
  `chk_participants_user_xor_contact` plus partial unique indexes on
  `(event_id, user_id)` / `(event_id, contact_id)`), `role`
  (`ParticipantRole`), `status` (`ParticipantStatus`, defaults `INVITED`),
  `pickupAddress`/`pickupLat`/`pickupLng` (for a `DRIVER` this is their trip-start
  anchor, not a pickup — see `common.geo.GeoPoint`), and `vehicle` (meaningful
  only when `role == DRIVER`).
- `EventParticipantRepository` — lookups by event/user/contact, a bulk
  `clearVehicleByVehicleId` update (used before deleting a vehicle), and
  projection queries (`countActiveByEventId`, `countParticipantsByEventIds`) that
  exclude `NON_ATTENDING` statuses for dashboard counts.
- `ParticipantDisplayResolver` — resolves `displayName`/`displayEmail` (Contact
  wins over User) and `priorAssignableStatus` (the status an `ASSIGNED`
  participant reverts to when unassigned: `READY` for Contact-backed, `CONFIRMED`
  for legacy user-backed, since Contact-backed rows skip the approval flow
  entirely).
- `EventParticipantMapper` — entity -> `EventParticipantResponse`.
- `EventParticipantService` — the two parallel flows plus shared per-event edits:
  - **Legacy self-join**: `selfJoin` (role must be DRIVER/PASSENGER/
    INDEPENDENT_ATTENDEE, event must be `OPEN` -> `REQUESTED`), `approve`/
    `reject` (organizer, `REQUESTED` -> `APPROVED`/`REJECTED`), `confirm`
    (participant, `APPROVED` -> `CONFIRMED`), `cancel`/`rejoin`.
  - **Organizer-first**: `addFromContact`/`addFromContacts` — validates the
    Contact is active and not already an active participant (reactivates a
    `CANCELLED` row instead of duplicating), copies the Contact's default
    pickup location at creation time only, lands the row at `READY` immediately
    (no approval step).
  - **Shared per-event edits**: `organizerUpdate` (role/pickup, event-local,
    never touches the Contact), `setPickup` (passenger only), `setTripStart`
    (driver only), `setVehicle` (driver's own vehicle, or the organizer acting
    for a Contact-backed driver who has no login), `remove` (soft: sets
    `CANCELLED`, blocked while `ASSIGNED`).
  - Every mutation asserts the participant's current status is in an explicit
    allowed set before transitioning — see the `*_STATES` constants at the top
    of the class for the exact state-machine edges enforced today.
- `EventParticipantController` — `/api/v1/events/{eventId}/participants`: self-join,
  list, `/from-contact`, `/from-contacts`, organizer PATCH, approve/reject/
  confirm/cancel/rejoin, `/pickup`, `/trip-start`, `/vehicle`, and soft-remove.
- [`dto/`](dto/README.md) — request/response records.

## How it connects

- Depends on `event/EventService` (organizer/event guards),
  `contact/ContactService` (`requireActiveContact`), `vehicle/VehicleService`
  (`requireOwnedByContact`/`requireOwnedByOrganizer`), `user/UserRepository`.
- `event/assignment/AssignmentService` and `event/planning/AutoAssignmentService`
  filter `EventParticipantEntity` by role/status/vehicle/pickup-completeness to
  build trips, and mutate `status` to `ASSIGNED` on placement.
- `trip/` and `tripstop/` reference `EventParticipantEntity` directly
  (`TripEntity.driverParticipant`, `TripStopEntity.participant`).
- Participates in the `ParticipantStatus` state machine from `common.enums` —
  see that enum's doc comment for which statuses are legacy-only vs.
  organizer-first.
