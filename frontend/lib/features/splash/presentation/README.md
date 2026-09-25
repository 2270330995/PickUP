# features/splash/presentation

The initial loading screen shown while auth state is being resolved.

## Contents

- `splash_screen.dart` — `SplashScreen`: static logo + app name +
  `CircularProgressIndicator`. No providers, no logic — it's purely what
  renders while `core/router`'s redirect holds the app at `/` because
  `authProvider`'s `AuthStatus` is still `loading`.

## How it connects

Routed at `RoutePaths.splash` (`/`), the app's `initialLocation`.
`core/router/app_router.dart`'s redirect keeps the app here until
`AuthController`'s refresh-token bootstrap resolves, then redirects to
`/login` or `/organizer`.
