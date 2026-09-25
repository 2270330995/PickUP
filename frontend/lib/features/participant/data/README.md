# features/participant/data

API client and DTOs for `EventParticipant` — a person's (Contact- or user-
backed) membership in one event, its role, status, and per-event pickup/
vehicle details.

## Contents

- `participant_api.dart` (`ParticipantApi`, all under
  `/events/{eventId}/participants`):
  - `list(eventId)` — `GET`.
  - `selfJoin(eventId, JoinEventRequest)` — `POST` (legacy self-join path).
  - `addFromContact` / `addFromContacts` — `POST .../from-contact` and
    `.../from-contacts`: organizer adds one or more Contacts from the People
    roster; `addFromContacts` is all-or-nothing.
  - `organizerUpdate(eventId, participantId, OrganizerUpdateParticipantRequest)`
    — `PATCH`: organizer edits role/pickup, event-local only.
  - `approve` / `reject` / `confirm` / `cancel` / `rejoin` — `POST .../<verb>`
    lifecycle transitions on `ParticipantStatus`.
  - `remove(eventId, participantId)` — `DELETE`.
  - `setVehicle` — `PATCH .../vehicle`: driver attaches/clears a vehicle.
  - `setPickup` — `PATCH .../pickup`: passenger sets pickup location.
  - `setTripStart` — `PATCH .../trip-start`: driver sets their route start
    location.
  - `participantApiProvider`, `eventParticipantsProvider` (family by
    eventId, autoDispose).
- `participant_dtos.dart`
  - `ParticipantRole` (`organizer`, `driver`, `passenger`,
    `independentAttendee`, `unknown`) and `ParticipantStatus` (`invited`,
    `requested`, `approved`, `rejected`, `confirmed`, `ready`, `assigned`,
    `checkedIn`, `pickedUp`, `arrived`, `cancelled`, `noShow`, `unknown`) —
    mirror the backend's `ParticipantRole`/`ParticipantStatus` enums, with
    `*FromString`/`*Label` helpers.
  - `EventParticipantResponse` — `userId` set for legacy self-joins,
    `contactId` set for organizer-added rows (`isContactBacked`); `displayLabel`
    picks whichever name is populated. Carries pickup address/lat/lng,
    `vehicleId`, and `ParticipantVehicleSummary`.
  - Request DTOs: `JoinEventRequest`, `AddContactParticipantRequest`,
    `AddContactsFromRosterRequest`, `OrganizerUpdateParticipantRequest`,
    `UpdateParticipantVehicleRequest`, `UpdateParticipantPickupRequest`.

## How it connects

Backs the participant roster and actions in
`features/event/presentation/event_detail_screen.dart`,
`add_from_people_sheet.dart`, and `organizer_participant_edit_sheet.dart`.
Feeds eligibility checks in `features/assignment/presentation`. Talks to the
backend's `participant/` package, which the repo's `CLAUDE.md` describes as
implementing the organizer-first Contact-backed vs. legacy user-backed
distinction.
