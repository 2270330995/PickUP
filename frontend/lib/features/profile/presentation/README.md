# features/profile/presentation

The organizer's own account screen.

## Contents

- `profile_screen.dart` — `ProfileScreen`:
  - Reads `currentUserProvider` (`features/user/data`); shows read-only
    email plus editable full name/phone form, saved via
    `UserApi.updateMe`.
  - On save, also calls `authProvider.notifier.updateCachedUser(...)` so the
    cached `AuthState.user` (used elsewhere in the app) reflects the edit
    immediately without waiting for a re-login.
  - Links to "My vehicles" (`RoutePaths.vehicles`) and "My trips"
    (`RoutePaths.myTrips`).
  - "Sign out" button calls `authProvider.notifier.signOut()`.

## How it connects

Depends on `features/user/data` (profile fetch/update) and
`shared/providers/auth_provider.dart` (cache sync + sign out). Routed at
`RoutePaths.profile` (`/profile`), linked from
`features/organizer/presentation/organizer_dashboard_screen.dart`'s app bar.
