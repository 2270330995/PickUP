# event/dto

Request/response records for event CRUD, lifecycle, and dashboards.

## What's in it

- `CreateEventRequest` — title, optional description, destination
  address+lat+lng (all required together), and a `@Future eventTime`.
- `UpdateEventRequest` — same fields, all optional (partial update); touching any
  destination field re-validates the full triad in `EventService`.
- `EventResponse` — the general-purpose event read model: organizer info, status,
  planning status, `assignmentGenerated`, `participantCount`, and — when the
  caller's own participant row is known — `currentUserParticipantRole`/`Status`
  (null on endpoints that don't resolve a viewer-specific row).
- `EventDashboardResponse` — single-event dashboard: `Totals` (participants by
  role, pending requests) and `Seats` (capacity vs. passengers needing rides,
  `driversMissingVehicle`).
- `EventDashboardSummary` — the condensed per-event row used inside the
  organizer-wide dashboard list.
- `OrganizerDashboardResponse` — `totalEvents`, `activeEvents`, and the list of
  `EventDashboardSummary`.

## How it connects

Built by `EventMapper`/`EventService` in the parent `event/` package; returned by
`EventController` and `OrganizerDashboardController`. `EventResponse` also flows
through `event/assignment` (organizer-viewer role checks) and is referenced by
callers across `trip/` and `participant/` that need event context.
