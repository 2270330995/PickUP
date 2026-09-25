# vehicle

Vehicle records, owned by an organizer's Contact (not by a driver's own account —
Contacts have no login). This is a Phase 4D-1 ownership move; see
`contact/README.md` and the root `CLAUDE.md`'s organizer-first model.

## What's in it

- `VehicleEntity` — `contact` (owning `ContactEntity`), optional `label`,
  `make`, `model`, optional `color`/`plate`, `seats`, optional `notes`.
- `VehicleRepository` — `findAllByContactIdOrderByCreatedAtAsc`,
  `findByIdAndContactId`.
- `VehicleMapper` — entity -> `VehicleResponse`.
- `VehicleService` — all mutation is contact-scoped and re-verifies organizer
  ownership of the contact on every call:
  - `listForContact`/`createForContact`/`updateVehicle`/`deleteVehicle`.
  - `updateVehicle` rejects a seat-count change while the vehicle is referenced
    by an existing trip (`TripRepository.existsByVehicleId`).
  - `deleteVehicle` rejects while trip-referenced; otherwise clears any
    per-event driver linkage first
    (`EventParticipantRepository.clearVehicleByVehicleId`) to keep the FK clean.
  - `requireOwnedByContact(vehicleId, contactId)` — the specific-contact
    ownership check used by organizer-driven participant vehicle selection.
  - `requireOwnedByOrganizer(vehicleId, organizerId)` — broader
    owns-via-some-contact check, used for the legacy self-service path (now
    effectively dead since that UI is hidden) and organizer-acting-for-a-legacy-
    driver vehicle selection.
- `VehicleController` — legacy `/api/v1/vehicles` endpoints, all kept compiling
  but rejecting every call with a `BadRequestException` pointing callers at
  `contact/ContactVehicleController` instead.
- [`dto/`](dto/README.md) — request/response records.

## How it connects

- The real mutation entry point is `contact/ContactVehicleController`
  (`/api/v1/contacts/{contactId}/vehicles`), which delegates straight into
  `VehicleService`.
- `participant/EventParticipantService.setVehicle`/`addFromContact(s)` call
  `requireOwnedByContact`/`requireOwnedByOrganizer` when a driver participant
  selects a vehicle for an event.
- `event/planning/DriverPassengerScorer` reads `VehicleEntity.seats` to compute
  driver capacity; `event/assignment/AssignmentService` validates seat capacity
  against the submitted passenger list.
