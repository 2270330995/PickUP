# features/dashboard

Read-only summary data for the organizer: an all-events overview and a
per-event participant/seat breakdown. This feature has no screens of its own
— it's a data layer consumed by `features/organizer` and `features/event`.

## Subdirectories

- [`data/`](data/README.md) — `DashboardApi` and its DTOs
  (`OrganizerDashboardResponse`, `EventDashboardResponse`).

## How it connects

`organizerDashboardProvider` feeds
`features/organizer/presentation/organizer_dashboard_screen.dart`;
`eventDashboardProvider` feeds `features/event/presentation/event_detail_screen.dart`.
Both are invalidated after assignment changes (see
[`features/assignment`](../assignment/README.md)).
