# core

Shared infrastructure used by every feature: HTTP client setup, routing,
token storage, theming, and small platform-launch/formatting helpers. Nothing
in `core/` depends on `features/`; it's the substrate features are built on.

## Subdirectories

- [`format/`](format/README.md) — pure ETA-formatting helper functions used
  by trip/stop UIs.
- [`launch/`](launch/README.md) — `launchExternalUrl`, wraps `url_launcher`
  with SnackBar error handling for deep links (e.g. driver navigation).
- [`network/`](network/README.md) — the shared `Dio`/`ApiClient` setup, the
  `ApiResponse<T>`/`ApiError` envelope model, and `ApiException` used by
  every feature's API client.
- [`router/`](router/README.md) — `go_router` route table (`RoutePaths`) and
  the auth-gated `appRouterProvider`.
- [`storage/`](storage/README.md) — `TokenStorage`, persists JWT access/
  refresh tokens (secure storage on mobile/web, shared preferences on
  desktop).
- [`theme/`](theme/README.md) — `AppTheme`, the app's Material 3 light/dark
  theme.
