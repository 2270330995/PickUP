# user/dto

Request/response records for the organizer's own account.

## What's in it

- `UpdateUserRequest` — only `fullName` and `phone` are mutable; email/password
  changes are not exposed here.
- `UserResponse` — the public projection of `UserEntity`: `id`, `email`,
  `fullName`, `phone`, `systemRoles`, `createdAt`. Entities are never returned
  directly — always mapped via `UserMapper`.

## How it connects

Produced/consumed by `UserService`/`UserController` in the parent `user/`
package; `UserResponse` is also embedded in `auth/dto.AuthResponse`.
