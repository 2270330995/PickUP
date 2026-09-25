# db/migration

Flyway-managed schema. `spring.jpa.hibernate.ddl-auto` is set to `validate` (see
root `CLAUDE.md`), meaning Hibernate never generates or alters schema at
runtime — it only checks that these migrations match the JPA entity mappings at
startup and fails fast if they don't. All schema changes go through a new
versioned SQL file here.

## Naming/ordering convention

- Files are named `V{n}__description.sql` (double underscore before the
  description), applied in strictly increasing `{n}` order and tracked in
  Flyway's history table. `{n}` is a plain integer here (`V1`, `V2`, ...), not a
  timestamp.
- **Never edit an existing migration** once it has shipped — add a new
  `V{n+1}__...sql` instead, even for a fix. Editing a checksummed migration
  breaks Flyway's validation for anyone who already applied it.
- A local Postgres volume created before a baseline change won't match a new
  baseline; wipe it with `docker compose down -v` (or drop/recreate the local
  database) rather than trying to migrate through it.

## What's here today

- `V1__baseline_4d1.sql` — the full Phase 4D-1 baseline schema in one file:
  `users` (+ `user_system_roles`), `events`, `contacts` (organizer-owned people
  roster), `vehicles` (owned by `contacts`, not `users` — the Phase 4D-1
  ownership move), `event_participants` (still `user_id`-only at this point),
  `trips` and `trip_stops` (mutually referential — the `trips -> trip_stops` FK
  on `current_stop_id` is added after `trip_stops` exists), and `notifications`.
  IDs are application-generated UUIDs (Hibernate), so no DB-side PK defaults are
  needed.
- `V2__event_participants_contacts.sql` — Phase 4D-2: makes `event_participants`
  support either a `user_id` or a `contact_id` (exactly one, enforced by
  `chk_participants_user_xor_contact` plus two partial unique indexes replacing
  the old single unique constraint), and adds `trips.driver_participant_id` so a
  trip's driver can be a Contact-backed participant instead of a `UserEntity`
  (`chk_trips_driver_ref` requires at least one of `driver_id` /
  `driver_participant_id`).

Together these two migrations implement the organizer-first pivot described in
the root `CLAUDE.md`: participants and trip drivers can be backed by either a
registered `UserEntity` (legacy self-join) or an organizer-owned `ContactEntity`,
with the database enforcing the exclusivity that the JPA entities
(`participant/EventParticipantEntity`, `trip/TripEntity`) assume.
