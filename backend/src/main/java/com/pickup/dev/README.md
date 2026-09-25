# dev

Local-development-only demo data seeding. Gated so it never runs in production.

## What's in it

- `DevProperties` — `@ConfigurationProperties(prefix = "pickup.dev")` record:
  `enabled` (exposes the unauthenticated `/api/v1/dev/**` endpoints and lets
  `SecurityConfig` permit them), `autoSeed` (seed on startup if the DB has no
  users), `password` (shared demo password, defaults to `"test"` if blank).
- `DevSeedService` — organizer-first seed: one organizer (`john@test.com`), a
  roster of `SEED_CONTACTS` (two drivers with vehicles, six passengers with
  pickup defaults), and a demo event with every contact already added as a
  `READY` participant so auto-assignment can be exercised immediately. `seed()`
  is idempotent per contact/event (looks up by name/title before creating).
  `listAccounts()` returns just the demo login info.
- `DevSeedController` — `@ConditionalOnProperty(pickup.dev.enabled)`:
  `POST /api/v1/dev/seed`, `GET /api/v1/dev/accounts`.
- `DevAutoSeedRunner` — `ApplicationRunner`, active only when
  `pickup.dev.auto-seed=true`; seeds once on startup if `UserRepository.count()
  == 0`, then logs the demo login.
- [`dto/`](dto/README.md) — response records.

## How it connects

Depends on `user/`, `event/`, `participant/`, `contact/`, `vehicle/` repositories
directly (constructs entities itself rather than going through their services,
since it needs full control over idempotent seeding). `config/SecurityConfig`
reads `DevProperties.enabled()` to decide whether `/api/v1/dev/**` is public.
Enabled via the `local` and `docker` Spring profiles per the root `CLAUDE.md`.
