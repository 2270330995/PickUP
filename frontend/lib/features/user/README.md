# features/user

The logged-in organizer's own account data. There are no screens in this
package — `features/profile` owns the UI, this package owns the API client.

## Subdirectories

- [`data/`](data/README.md) — `UserApi`, `UserResponse`,
  `currentUserProvider`.

## How it connects

`currentUserProvider` is the app-wide "who am I" provider, consumed well
beyond `features/profile` (e.g. `features/event/presentation` for organizer
checks, `features/passenger/presentation` for stop highlighting).
