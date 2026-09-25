# common/domain

Shared JPA base class.

## What's in it

- `BaseEntity` — `@MappedSuperclass` providing `createdAt`/`updatedAt` via Spring
  Data's `@CreatedDate`/`@LastModifiedDate` and `AuditingEntityListener`. Every
  entity in the app (`UserEntity`, `EventEntity`, `ContactEntity`,
  `EventParticipantEntity`, `TripEntity`, `TripStopEntity`, `VehicleEntity`,
  `NotificationEntity`) extends it.

## How it connects

Requires JPA auditing to be enabled (via Spring Boot auto-configuration) so the
timestamps populate on persist/update. Fields are read-only (`@Getter` only, no
setter) so callers can't accidentally overwrite audit data.
