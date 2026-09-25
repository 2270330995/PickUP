# com.pickup

Root package of the Pick Up! Spring Boot backend. Organized feature-per-package
(not layer-per-package): each domain area holds its own entity, repository,
service, controller, and `dto/` subpackage together. See the root `CLAUDE.md` for
the full architecture overview (organizer-first model, auto-assignment pipeline,
API envelope, state machines, migrations).

- `PickUpApplication` — Spring Boot entry point (`main`).

## Feature packages

- [`auth/`](auth/README.md) — JWT register/login/refresh for the organizer's
  account.
- [`common/`](common/README.md) — cross-cutting API envelope, base entity,
  shared enums/state machines, typed exceptions, and geo/routing utilities.
- [`config/`](config/README.md) — Spring Security and WebSocket wiring.
- [`contact/`](contact/README.md) — the organizer's reusable People roster
  (drivers/passengers with no login of their own).
- [`dev/`](dev/README.md) — local-only demo data seeding.
- [`event/`](event/README.md) — event CRUD/lifecycle, dashboards, manual
  assignment ([`event/assignment/`](event/assignment/README.md)), and the
  auto-assignment pipeline ([`event/planning/`](event/planning/README.md)).
- [`location/`](location/README.md) — server-side Google Places resolution.
- [`notification/`](notification/README.md) — notification persistence model
  (delivery flow not yet built).
- [`participant/`](participant/README.md) — an event's roster: legacy
  self-joined or organizer-added Contact-backed participants.
- [`security/`](security/README.md) — JWT filter, token provider, Spring
  Security principal, `CurrentUser` accessor.
- [`trip/`](trip/README.md) — trip entity and driver execution lifecycle, plus
  [`trip/navigation/`](trip/navigation/README.md) (deep links) and
  [`trip/planning/`](trip/planning/README.md) (ETA enrichment).
- [`tripstop/`](tripstop/README.md) — a single ordered pickup stop on a trip.
- [`user/`](user/README.md) — the organizer's own account.
- [`vehicle/`](vehicle/README.md) — vehicle records owned by a Contact.
