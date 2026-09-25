# event

Event CRUD, lifecycle, and organizer/event dashboards — the container an
organizer creates, adds Contacts/participants to, and runs assignment against.

## What's in it

- `EventEntity` — `organizer`, `title`, `description`, destination
  address/lat/lng, `eventTime`, `status` (`EventStatus`, lifecycle), separately
  `planningStatus` (`EventPlanningStatus`, auto-assignment progress — orthogonal
  to lifecycle), and `assignmentGenerated`.
- `EventRepository` — `findAllByOrganizerId(OrderByEventTimeAsc)`,
  `findAllByStatusOrderByEventTimeAsc`.
- `EventMapper` — entity (+ optional viewer role/status) -> `EventResponse`.
- `EventService` — the hub other packages call into:
  - CRUD + lifecycle: `createEvent` (also creates the organizer's own
    `CONFIRMED` `ORGANIZER` participant row), `updateEvent` (only while
    `DRAFT`/`OPEN`/`CLOSED`), `closeEvent`/`reopenEvent`
    (`OPEN`<->`CLOSED`), `cancelEvent` (any non-terminal state ->
    `CANCELLED`), `deleteEvent` (only `DRAFT`/`CANCELLED`, cascades participant
    deletion first).
  - Listing: `listMyEvents`, `listJoinedEvents` (legacy self-join, excludes
    `ORGANIZER` rows), `listOpenEvents` (excludes events the caller already
    joined).
  - `loadOrThrow` / `requireOrganizer` — shared guards used across `event/*`,
    `participant/`, `vehicle/`, and `trip/`.
  - `getEventDashboard` / `getOrganizerDashboard` — aggregate participant counts
    by role/status into `EventDashboardResponse`/`OrganizerDashboardResponse`,
    carefully excluding non-attending statuses (`INVITED, REQUESTED, REJECTED,
    CANCELLED, NO_SHOW`) so "total participants" matches what's shown elsewhere.
- `EventController` — `/api/v1/events` CRUD, `scope=mine|open|joined` listing,
  lifecycle actions (`/close`, `/reopen`, `/cancel`), `/dashboard`, and
  `/planning/generate-assignments` (delegates to
  `event/planning/AutoAssignmentService`).
- `OrganizerDashboardController` — `GET /api/v1/organizer/dashboard`.
- [`assignment/`](assignment/README.md) — manual + persisted assignment plans.
- [`dto/`](dto/README.md) — request/response records.
- [`planning/`](planning/README.md) — the auto-assignment pipeline.

## How it connects

- `EventService` is a dependency of nearly every other feature package:
  `participant/`, `vehicle/` (indirectly via `contact`), `event/assignment`, and
  `event/planning` all call `loadOrThrow`/`requireOrganizer`.
- Participates in two orthogonal state machines from `common.enums`:
  `EventStatus` (lifecycle) and `EventPlanningStatus` (assignment progress).
- See the root `CLAUDE.md`'s "Organizer-first model" section — event creation
  auto-adds the organizer as a `CONFIRMED` participant, but Contact-backed
  participants (added via `participant/`) skip straight to `READY`.
