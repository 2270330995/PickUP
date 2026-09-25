# features/participant

Manages `EventParticipant` records: a Contact's or user's membership in one
event, their role, lifecycle status, and per-event pickup/vehicle details.
Central to the organizer-first model's Contact-backed vs. legacy user-backed
distinction (see the repo's `CLAUDE.md`).

## Subdirectories

- [`data/`](data/README.md) — `ParticipantApi` and the `ParticipantRole`/
  `ParticipantStatus` enums plus request/response DTOs.
- [`presentation/`](presentation/README.md) — pickup/trip-start location
  bottom sheets.

## How it connects

Consumed heavily by `features/event/presentation` (roster display,
moderation actions, add-from-people) and `features/assignment/presentation`
(eligibility filtering for drivers/passengers). No screens of its own beyond
the two bottom sheets — the roster UI lives in `features/event`.
