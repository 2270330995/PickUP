# contact

The organizer's reusable People roster — the core of the organizer-first model
described in the root `CLAUDE.md`. A `ContactEntity` is a driver/passenger known
to one organizer, with no login of their own; it's reused across events instead
of the legacy self-join flow.

## What's in it

- `ContactEntity` — `organizer` (owning `UserEntity`), `name`, optional
  `phone`/`email`, `defaultAddress`/`defaultLat`/`defaultLng`, `notes`,
  `preferredRole` (a `ParticipantRole` UX hint only — the real per-event role
  lives on `EventParticipantEntity.role`), `claimedByUser` (reserved, unused, for
  a future account-claiming feature), and `archivedAt` (soft-archive marker —
  contacts are never hard-deleted since events reference them historically).
- `ContactRepository` — `findAllByOrganizerIdAndArchivedAtIsNullOrderByNameAsc`,
  `findByIdAndOrganizerId`.
- `ContactMapper` — entity + externally-computed vehicle count -> `ContactResponse`.
- `ContactService` — CRUD plus soft-archive:
  - `createContact` validates the organizer exists and the optional default
    location is complete-or-absent (`GeoLocationValidator`), rejects
    `preferredRole == ORGANIZER`.
  - `updateContact` is a partial update; touching any of the three location
    fields re-validates the full triad.
  - `archiveContact` is idempotent (archiving twice is a no-op success).
  - `requireActiveContact(organizerId, contactId)` is the shared guard other
    packages call to load a contact scoped to its owner and reject archived ones
    with 404.
- `ContactController` — `/api/v1/contacts` CRUD (`GET`, `POST`, `GET/{id}`,
  `PATCH/{id}`, `DELETE/{id}` which archives).
- `ContactVehicleController` — `/api/v1/contacts/{contactId}/vehicles`, delegating
  straight to `vehicle/VehicleService` (vehicles are owned by a Contact, not a
  User — see `vehicle/README.md`).
- [`dto/`](dto/README.md) — request/response records.

## How it connects

- `participant/EventParticipantService.addFromContact(s)` reads Contacts via
  `ContactService.requireActiveContact` and copies `defaultAddress`/`defaultLat`/
  `defaultLng` onto the new `EventParticipantEntity` at creation time only (later
  edits are event-local and never write back — see `participant/README.md`).
- `vehicle/VehicleService` and `dev/DevSeedService` both depend on
  `ContactRepository`/`ContactService`.
- Every controller here requires an authenticated organizer via
  `security/CurrentUser`.
