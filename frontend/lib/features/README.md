# features

Feature-based modules mirroring the backend's domains (per the repo's
`CLAUDE.md`). Each feature holds its own `data/` (dio-based API client + DTOs)
and/or `presentation/` (screens/widgets, Riverpod for state) subpackage.
Screens are wired into the app via `core/router`; most features depend on
`core/network`'s `ApiClient` for their data layer.

| Feature | User-facing capability |
| --- | --- |
| [`assignment`](assignment/README.md) | Organizer builds/saves an event's driver-passenger assignment plan, manually or via auto-assignment. |
| [`auth`](auth/README.md) | Organizer registration, login, and (via `shared/providers`) session bootstrap/logout. |
| [`dashboard`](dashboard/README.md) | Read-only summary data: all-events overview and per-event participant/seat counts. |
| [`dev`](dev/README.md) | Debug-only demo-data seeding and quick-login accounts (local/docker backend only). |
| [`driver`](driver/README.md) | Driver-mode trip screen for a legacy self-join (user-backed) driver. |
| [`event`](event/README.md) | Create/browse events; the event detail hub (participants, assignments, lifecycle). |
| [`location`](location/README.md) | Google Places address autocomplete and location-picker widgets used across the app. |
| [`organizer`](organizer/README.md) | The organizer's post-login landing dashboard. |
| [`participant`](participant/README.md) | An event participant's role/status/pickup/vehicle record and its lifecycle actions. |
| [`passenger`](passenger/README.md) | Passenger-mode trip screen for a user-backed rider tracking their ride. |
| [`people`](people/README.md) | The organizer's reusable Contact roster (drivers/passengers with no login) and their vehicles. |
| [`profile`](profile/README.md) | The organizer's own account screen (edit name/phone, sign out). |
| [`splash`](splash/README.md) | Initial loading screen shown while session bootstrap resolves. |
| [`trip`](trip/README.md) | Generated trips and ordered pickup stops; driver execution flow (start/pick up/complete). |
| [`user`](user/README.md) | The logged-in organizer's own account data (`/users/me`). |
| [`vehicle`](vehicle/README.md) | The legacy user-owned vehicle garage, for self-join drivers. |

## How it connects

`core/router/app_router.dart` imports a screen from nearly every
`presentation/` package here to build the route table. `event` is the hub
most other features link into (assignment, participant, dashboard, people,
vehicle, location, trip). See [`../core/README.md`](../core/README.md) for
the shared infrastructure these all build on and
[`../shared/README.md`](../shared/README.md) for the one piece of
cross-feature state (`authProvider`).
