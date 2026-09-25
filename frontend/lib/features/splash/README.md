# features/splash

The app's initial loading screen, shown while session bootstrap resolves.
Presentation only, no data layer.

## Subdirectories

- [`presentation/`](presentation/README.md) — `SplashScreen`.

## How it connects

Routed at `/`, the app's initial location; see
[`core/router`](../../core/router/README.md) for the auth-gated redirect
logic that leaves this screen.
