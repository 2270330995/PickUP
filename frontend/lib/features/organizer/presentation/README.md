# features/organizer/presentation

The organizer's home screen after login.

## Contents

- `organizer_dashboard_screen.dart` — `OrganizerDashboardScreen`:
  - App bar shortcuts to People, Browse events, My trips, Profile.
  - Stat cards for total/active events (`organizerDashboardProvider`,
    `features/dashboard/data`).
  - "My events" list (`OrganizerDashboardResponse.events`, one
    `_EventSummaryCard` each) linking to event detail.
  - "Events I've joined" list (`joinedEventsProvider`,
    `features/event/data`) for the legacy self-join path, showing the
    viewer's own participant role/status as chips.
  - Floating action button to create a new event.

## How it connects

The default landing route after authentication
(`RoutePaths.organizer` — `core/router`'s redirect sends authenticated users
here from splash/login/register). Depends on `features/dashboard/data` and
`features/event/data`; links out to `features/people`, `features/event`,
`features/trip`, `features/profile`.
