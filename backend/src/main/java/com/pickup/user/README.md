# user

The one kind of login in the app — the organizer's account (see "Organizer-first
model" in the root `CLAUDE.md`; Contacts, by contrast, never get a `UserEntity`).

## What's in it

- `UserEntity` — `email` (unique), `passwordHash`, `fullName`, optional `phone`,
  `systemRoles` (`Set<SystemRole>`, eager-fetched element collection, defaults
  `{USER}`), `fcmToken` (column exists; nothing populates or reads it yet — see
  `notification/README.md`).
- `UserRepository` — `findByEmail`, `existsByEmail`.
- `UserMapper` — entity -> `UserResponse`.
- `UserService` — `getCurrentUser`, `updateCurrentUser` (partial: blank `phone`
  clears it, blank `fullName` is ignored rather than clearing a required field).
- `UserController` — `GET/PATCH /api/v1/users/me`,
  `GET /api/v1/users/me/trips` (delegates to `trip/TripService.listMyTrips`),
  `POST /api/v1/users/me/fcm-token` (`501`, not implemented).

## How it connects

- `auth/AuthService` creates and authenticates `UserEntity` rows directly.
- `security/CustomUserDetailsService` and `PickUpUserDetails` wrap `UserEntity`
  for Spring Security.
- Every other feature package that has a legacy "self-join" concept
  (`participant`, `contact.ContactEntity.claimedByUser`,
  `trip.TripEntity.driver`) references `UserEntity`, but the organizer-first
  flow increasingly routes through `contact/ContactEntity` instead — see
  `participant/README.md`.
- [`dto/`](dto/README.md) — request/response records.
