# participant/dto

Request/response records covering both the legacy self-join flow and the
organizer-first Contact-adding flow.

## What's in it

- `JoinEventRequest` — legacy self-join: `role` (`DRIVER`/`PASSENGER`/
  `INDEPENDENT_ATTENDEE` only), optional pickup address/lat/lng.
- `AddContactParticipantRequest` — organizer adds one Contact: `contactId`,
  `role`, optional `vehicleId`, optional pickup override (falls back to the
  Contact's default location when omitted).
- `AddContactsFromRosterRequest` — a non-empty list of
  `AddContactParticipantRequest`, processed atomically (all-or-nothing).
- `OrganizerUpdateParticipantRequest` — organizer edits a participant's per-event
  `role`/pickup; all fields optional, but pickup fields must be supplied
  together. Event-local only — never writes back to the Contact.
- `UpdateParticipantPickupRequest` — passenger sets/updates their own pickup
  (all three fields required together).
- `UpdateParticipantVehicleRequest` — driver/organizer sets or clears
  (`vehicleId = null`) the participant's vehicle for this event.
- `EventParticipantResponse` — the unified read model for both self-joined and
  Contact-backed rows: resolved `displayName`/`displayEmail` (see
  `ParticipantDisplayResolver`), raw `userFullName`/`userEmail` when
  user-backed, role/status, pickup fields, and an inlined `VehicleSummary` so UIs
  don't need a follow-up fetch.

## How it connects

Consumed by `EventParticipantController`, produced by
`EventParticipantMapper`/`EventParticipantService` in the parent `participant/`
package. `role` uses `common.enums.ParticipantRole`; `status` uses
`common.enums.ParticipantStatus`.
