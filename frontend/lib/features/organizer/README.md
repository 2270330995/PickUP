# features/organizer

The organizer's landing screen after login. Contains presentation only — it
composes data from `features/dashboard` and `features/event` rather than
owning any API client of its own.

## Subdirectories

- [`presentation/`](presentation/README.md) — `OrganizerDashboardScreen`.

## How it connects

Routed at `/organizer` (`RoutePaths.organizer`), the post-login landing
page. See [`features/dashboard`](../dashboard/README.md) for the summary
data it renders.
