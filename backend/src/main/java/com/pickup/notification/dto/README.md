# notification/dto

Response record for the (not-yet-implemented) notifications feature.

## What's in it

- `NotificationResponse` — `id`, `type` (`NotificationType`), `title`, `body`,
  `read`, `createdAt`. Phase 1 placeholder — populated once notifications are
  wired.

## How it connects

Declared as the intended return type of `NotificationController`'s endpoints,
which currently throw `501` via `common/api/NotImplemented` rather than
returning this type.
