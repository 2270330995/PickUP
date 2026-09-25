# lib

Flutter app source for Pick Up!, a mobile-first carpool app for events. See
the repo's top-level `CLAUDE.md` for the product/architecture overview.

## Layout

- `main.dart` — entry point; wraps the app in a Riverpod `ProviderScope` and
  runs `PickUpApp`.
- `app.dart` — `PickUpApp`: builds `MaterialApp.router` from
  `core/theme/app_theme.dart` and `core/router/app_router.dart`.
- [`core/`](core/README.md) — shared infrastructure with no dependency on
  `features/`: HTTP client (`ApiClient`/`Dio`), the `ApiResponse`/
  `ApiException` envelope, `go_router` route table, token storage, theme, and
  small format/launch helpers.
- [`features/`](features/README.md) — one package per product capability
  (auth, events, participants, assignment, trips, people/contacts, vehicles,
  location, dashboard, profile, etc.), each typically split into `data/`
  (API client + DTOs) and `presentation/` (screens/widgets).
- [`shared/`](shared/README.md) — cross-feature state that `core/` needs
  without depending on a specific feature, currently just the app's
  authentication state machine (`shared/providers/auth_provider.dart`).

## How it connects

`core/` has zero knowledge of `features/`; `features/` depend on `core/` for
networking, routing, and storage; `shared/` bridges the two by holding auth
state that both `core/router` and `core/network` need to reference without
importing a feature package directly. See
[`features/README.md`](features/README.md) for a one-line summary of every
feature.
