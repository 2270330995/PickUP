# dev/dto

Response records for the dev-seed endpoints.

## What's in it

- `DevAccountInfo` — `email`, `fullName`, `role`, `password` for a demo login.
- `DevSeedResponse` — `eventId`, `eventTitle`, `alreadyExisted` (true if the seed
  found an existing demo event rather than creating one), and the list of
  `DevAccountInfo`.

## How it connects

Returned by `DevSeedController` / built by `DevSeedService` in the parent `dev/`
package.
