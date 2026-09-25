# features/user/data

API client and DTOs for the logged-in organizer's own account (the only kind
of user account in this app — see "Organizer-first model" in the repo's
`CLAUDE.md`).

## Contents

- `user_api.dart`
  - `UserApi.getMe()` — `GET /users/me`.
  - `UserApi.updateMe(UpdateUserRequest)` — `PATCH /users/me` (partial:
    full name and/or phone).
  - `userApiProvider` — `Provider<UserApi>`.
  - `currentUserProvider` — `FutureProvider.autoDispose<UserResponse>`,
    the canonical "who am I" provider used across features.
- `user_dtos.dart`
  - `UserResponse` — id, email, fullName, phone, `systemRoles`, createdAt.
  - `UpdateUserRequest` — fullName/phone, both optional/omit-if-null.

## How it connects

`currentUserProvider` is read wherever the app needs the viewer's identity:
`features/profile/presentation`, `features/event/presentation` (to
determine `isOrganizer`), `features/passenger/presentation` (to highlight
the viewer's own stop). Distinct from `AuthResponse.user`
(`features/auth/data`), which is the snapshot returned at login/refresh time
— `AuthController.updateCachedUser` keeps that snapshot in sync after a
profile edit here.
