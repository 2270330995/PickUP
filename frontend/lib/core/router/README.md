# core/router

Centralized `go_router` configuration: every route path and the redirect
(auth-gating) logic live here rather than in individual screens.

## Contents

- `route_paths.dart` — `RoutePaths`, a non-instantiable class of `static
  const` path strings (`/`, `/login`, `/register`, `/profile`, `/organizer`,
  `/events`, `/events/new`, `/events/:id`, `/people`, `/people/new`,
  `/people/:id`, `/people/:id/edit`, `/vehicles`, `/vehicles/new`,
  `/vehicles/:id/edit`, `/trips`, `/events/:id/assignments`,
  `/events/:id/trips`, `/driver/trips/:tripId`, `/passenger/rides/:tripId`,
  `/trips/:tripId/monitor`) plus `*For(id)` helper functions that interpolate
  path parameters for navigation calls (`context.go(RoutePaths.eventDetailFor(id))`).
- `app_router.dart` — `appRouterProvider`, a `Provider<GoRouter>`:
  - `redirect` implements the auth gate: while `authProvider` is loading,
    everything but `/` (splash) redirects to splash; when unauthenticated,
    everything but login/register redirects to `/login`; when authenticated,
    hitting splash/login/register redirects to `/organizer`.
  - `routes` maps every `RoutePaths` constant to its screen widget, pulling
    path parameters (e.g. `state.pathParameters['id']`) and, for the vehicle
    and contact edit routes, an optional `extra` payload (`VehicleResponse`/
    `ContactResponse`) passed by the caller to pre-populate the form without
    a second network round-trip — deep links without `extra` fall back to a
    blank add form.

## How it connects

`appRouterProvider` watches `shared/providers/auth_provider.dart`'s
`authProvider` for the redirect decision, and imports a screen widget from
nearly every feature's `presentation/` package (`assignment`, `auth`,
`driver`, `event`, `organizer`, `passenger`, `people`, `profile`, `splash`,
`trip`, `vehicle`). `lib/app.dart` consumes `appRouterProvider` to build the
`MaterialApp.router`. New routes should be added here, not hardcoded as
string literals in screens.
