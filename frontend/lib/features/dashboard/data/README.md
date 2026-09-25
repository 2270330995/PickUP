# features/dashboard/data

Read-only API client and DTOs for the organizer's summary dashboards.

## Contents

- `dashboard_api.dart`
  - `DashboardApi.getOrganizerDashboard()` — `GET /organizer/dashboard`:
    overview across all of an organizer's events.
  - `DashboardApi.getEventDashboard(eventId)` — `GET
    /events/{id}/dashboard`: per-event participant/seat totals.
  - `organizerDashboardProvider` — `FutureProvider.autoDispose<OrganizerDashboardResponse>`.
  - `eventDashboardProvider` — `FutureProvider.autoDispose.family<EventDashboardResponse,
    String>`.
- `dashboard_dtos.dart`
  - `OrganizerDashboardResponse` — `{totalEvents, activeEvents, events:
    List<EventDashboardSummary>}`; each summary carries id/title/time/status
    plus counts (`totalParticipants`, `confirmedDrivers`, `pendingRequests`,
    `seatsNeeded`). Reuses `EventStatus` from `features/event/data/event_dtos.dart`.
  - `EventDashboardResponse` — per-event detail: `EventDashboardTotals`
    (participants, organizers, confirmed drivers, passengers needing rides,
    independent attendees, pending requests) and `EventDashboardSeats`
    (seats available/needed/surplus, drivers missing a vehicle), plus
    `planningStatus`.

## How it connects

Both providers are invalidated by `features/assignment/presentation`
whenever an assignment plan is saved or auto-generated, since assignment
changes shift seat/participant counts. `organizerDashboardProvider` backs
`features/organizer/presentation/organizer_dashboard_screen.dart`;
`eventDashboardProvider` backs the per-event dashboard shown from
`features/event/presentation/event_detail_screen.dart`.
