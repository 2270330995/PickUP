# features/event/data

API client and DTOs for event CRUD and lifecycle transitions.

## Contents

- `event_api.dart`
  - `EventApi.listEvents({scope})` — `GET /events?scope=`, where scope is
    `mine` (organizer's own events), `open` (events the viewer hasn't joined,
    for browsing/self-join), or `joined` (events the viewer participates in).
  - `EventApi.get(id)` — `GET /events/{id}`.
  - `EventApi.create(CreateEventRequest)` — `POST /events`.
  - `EventApi.update(id, UpdateEventRequest)` — `PATCH /events/{id}`
    (partial update; each field is nullable/omit-if-null).
  - `EventApi.delete(id)` — `DELETE /events/{id}`.
  - `EventApi.close(id)` / `reopen(id)` / `cancel(id)` — `POST
    /events/{id}/close|reopen|cancel`, lifecycle transitions on `EventStatus`.
  - Providers: `eventApiProvider`, `eventDetailProvider` (family by id),
    `myEventsProvider` (scope=mine), `openEventsProvider` (scope=open),
    `joinedEventsProvider` (scope=joined) — all `FutureProvider.autoDispose`.
- `event_dtos.dart`
  - `EventStatus` enum (`draft`, `open`, `closed`, `inProgress`, `completed`,
    `cancelled`, `unknown`) with `eventStatusFromString`/`eventStatusLabel`.
  - `EventResponse` — id, organizer info, title/description, destination
    address+lat/lng, `eventTime`, status, `planningStatus`,
    `assignmentGenerated`, `participantCount`, and the viewer's own
    `currentUserParticipantRole`/`currentUserParticipantStatus` when known
    (uses `ParticipantRole`/`ParticipantStatus` from
    `features/participant/data/participant_dtos.dart`).
  - `CreateEventRequest` / `UpdateEventRequest` — request payloads; event
    times are serialized as UTC ISO-8601.

## How it connects

Backs `features/event/presentation` (browse/create/detail screens) and is
read by `features/dashboard`, `features/assignment`, and
`features/organizer` for event summaries and links. `eventDetailProvider`,
`myEventsProvider`, and `organizerDashboardProvider` are invalidated widely
across the app (participant actions, assignment saves) since almost every
mutation affects an event's derived state.
