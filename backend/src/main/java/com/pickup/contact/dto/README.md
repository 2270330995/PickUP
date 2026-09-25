# contact/dto

Request/response records for the organizer's People roster.

## What's in it

- `CreateContactRequest` — name (required), optional phone/email/default
  address+lat/lng/notes, and an optional `preferredRole` (UX hint only; must not
  be `ORGANIZER`).
- `UpdateContactRequest` — same fields, all optional; a blank string clears the
  field (service-level convention shared with `UpdateVehicleRequest` /
  `UpdateEventRequest`).
- `ContactResponse` — read model including a denormalized `vehicleCount` so the
  People list can render without a follow-up fetch per contact, plus
  `archivedAt`/`createdAt`/`updatedAt`.

## How it connects

Consumed by `ContactController` and produced by `ContactMapper`/`ContactService`
in the parent `contact/` package. `preferredRole` uses
`common.enums.ParticipantRole`, the same enum `EventParticipantEntity.role` uses
for the per-event role actually assigned later.
