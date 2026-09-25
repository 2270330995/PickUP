# notification

Notification persistence model — intentionally minimal; the delivery/read flow
is not yet built.

## What's in it

- `NotificationEntity` — `recipient` (`UserEntity`), `type`
  (`common.enums.NotificationType`), `title`, `body`, optional free-form
  `payloadJson`, `readAt`.
- `NotificationRepository` — `findAllByRecipientIdOrderByCreatedAtDesc`.
- `NotificationController` — `GET /api/v1/notifications`,
  `POST /{id}/read` — both currently `501 Not Implemented` via
  `common/api/NotImplemented.phase1(...)`.
- [`dto/`](dto/README.md) — the intended `NotificationResponse` read model.

## How it connects

No other package creates or reads `NotificationEntity` yet — the entity and
repository exist ahead of the feature (schema is in place via the V1 migration)
but nothing populates them. No FCM/push wiring exists despite `UserEntity`
carrying an `fcmToken` column.
