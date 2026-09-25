# features/auth/presentation

Sign-in and account-creation screens.

## Contents

- `login_screen.dart` — `LoginScreen`: email/password form that calls
  `authProvider.notifier.login(...)`. In `kDebugMode` only, renders a
  `_DevTestingPanel` that calls `DevApi.seed()` (`features/dev/data`) to
  populate demo data and lists `devAccountsProvider` accounts as one-tap
  quick-login buttons (all demo accounts share password `test`). Links to
  `RoutePaths.register`.
- `register_screen.dart` — `RegisterScreen`: full name/email/password/optional
  phone form that calls `authProvider.notifier.register(...)`.

Both screens show `ApiException.message` in a `SnackBar` on failure and
disable their submit button while the request is in flight.

## How it connects

Both call into `shared/providers/auth_provider.dart` rather than
`features/auth/data` directly, since successful login/register must also
persist tokens and flip global auth state for `core/router`'s redirect logic.
Routed at `RoutePaths.login` and `RoutePaths.register`. See
[`../data/README.md`](../data/README.md) for the underlying API contract.
