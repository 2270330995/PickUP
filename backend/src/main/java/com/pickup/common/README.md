# common

Cross-cutting code shared by every feature package: the API envelope, the JPA
base entity, shared enums/state machines, typed exceptions, and geo utilities.
Nothing here depends on a feature package (`event`, `trip`, `contact`, etc.) —
dependencies only flow the other way.

## What's in it

- [`api/`](api/README.md) — `ApiResponse`/`ApiError`/`PageResponse` envelope and
  the `NotImplemented` placeholder helper.
- [`domain/`](domain/README.md) — `BaseEntity` (`createdAt`/`updatedAt` auditing).
- [`enums/`](enums/README.md) — every state machine and role/type enum
  (`EventStatus`, `ParticipantStatus`, `TripStatus`, `StopStatus`, etc.).
- [`exception/`](exception/README.md) — `BaseException` subclasses and
  `GlobalExceptionHandler`.
- [`geo/`](geo/README.md) — `GeoPoint`, `DistanceCalculator`,
  `GeoLocationValidator`, and its [`routing/`](geo/routing/README.md) subpackage
  (`RouteEstimateService` and its providers).

## How it connects

Every feature package depends on some slice of `common`: controllers return
`ApiResponse` (`api`), entities extend `BaseEntity` (`domain`), services throw
`common.exception` types and filter/transition on `common.enums`, and anything
location-aware (`event`, `participant`, `trip`, `contact`) goes through
`common.geo`. See the root `CLAUDE.md` for how these threads combine into the
auto-assignment pipeline and the organizer-first model.
