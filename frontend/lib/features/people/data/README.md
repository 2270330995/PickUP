# features/people/data

API client and DTOs for the organizer's reusable **Contact** roster
(`ContactEntity` on the backend) and each Contact's vehicles — the
organizer-first model's replacement for requiring drivers/passengers to hold
their own PickUp account.

## Contents

- `contact_api.dart` (`ContactApi`, all under `/contacts`):
  - `list()` — `GET /contacts`: active (non-archived) contacts.
  - `get(id)` — `GET /contacts/{id}`.
  - `create(CreateContactRequest)` — `POST /contacts`.
  - `update(id, UpdateContactRequest)` — `PATCH /contacts/{id}`.
  - `archive(id)` — `DELETE /contacts/{id}` (soft-delete; hides from the
    roster, not reversible from the app yet).
  - `listVehicles` / `createVehicle` / `updateVehicle` / `deleteVehicle` —
    `GET|POST|PATCH|DELETE /contacts/{id}/vehicles[/​{vehicleId}]`.
  - Providers: `contactApiProvider`, `contactsProvider` (roster list),
    `contactDetailProvider` (family by id), `contactVehiclesProvider`
    (family by contact id) — all `FutureProvider.autoDispose`.
- `contact_dtos.dart`
  - `ContactResponse` — name, phone, email, default address/lat/lng,
    notes, `preferredRole` (a `ParticipantRole` hint, from
    `features/participant/data`), `vehicleCount`, `archivedAt`.
  - `CreateContactRequest` / `UpdateContactRequest`.
  - `ContactVehicleResponse` — a vehicle reusable across events, with
    `displayLabel` combining label/make/model/color/plate.
  - `CreateContactVehicleRequest` / `UpdateContactVehicleRequest`.

## How it connects

Backs `features/people/presentation` (roster CRUD UI) and is read from
`features/event/presentation/add_from_people_sheet.dart` and
`organizer_participant_edit_sheet.dart` when adding/editing a Contact-backed
event participant. A Contact's default address/vehicle only pre-fills an
event participant's fields — editing a participant never writes back here
(see the repo's `CLAUDE.md` "Organizer-first model" section).
