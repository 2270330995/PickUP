# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Pick Up! is a mobile-first carpool app for events. It coordinates an **organizer**
who manages a reusable roster of **Contacts** (drivers/passengers, no login of
their own), adds them to **Events**, and runs **auto-assignment** to build
**Trips** with ordered pickup stops. Backend is Spring Boot 3 (Java 21); frontend
is Flutter. The product direction shifted during development (see "Organizer-first
model" below) — some legacy self-join concepts still compile but are no longer the
primary flow.

## Commands

### Backend (`backend/`)

```bash
cd backend
./mvnw spring-boot:run              # run locally (profile `local`, default)
./mvnw test                         # run all tests
./mvnw test -Dtest=AssignmentServiceTest              # single test class
./mvnw test -Dtest=AssignmentServiceTest#methodName   # single test method
./mvnw package                      # build jar
```

Local dev needs Postgres running; the easiest path is `docker compose up postgres -d`
from the repo root (see below). The `local` profile connects to
`localhost:5432/pickup` with user/password `pickup/pickup`.

### Full stack via Docker (from repo root)

```bash
cp .env.example .env
docker compose up --build           # Postgres + backend, http://localhost:8080
docker compose down -v              # stop and wipe data (needed after a Flyway
                                     # baseline change — see "Migrations" below)
curl -X POST http://localhost:8080/api/v1/dev/seed     # re-seed demo data
curl http://localhost:8080/api/v1/dev/accounts         # list demo accounts
```

Demo login: `john@test.com` / `test` (organizer). Dev endpoints
(`/api/v1/dev/**`) are only enabled in the `local` and `docker` profiles.

### Frontend (`frontend/`)

```bash
cd frontend
flutter pub get
flutter test                                    # all tests
flutter test test/path/to/some_test.dart        # single file
flutter analyze                                 # lint

# Run against a backend the app can reach:
flutter run --dart-define=PICKUP_API_BASE_URL=http://10.0.2.2:8080     # Android emulator
flutter run --dart-define=PICKUP_API_BASE_URL=http://localhost:8080    # iOS sim / desktop
```

Platform shells (`android/`, `ios/`, `web/`, etc.) are regenerated with
`flutter create .` if missing — this preserves `lib/`.

## Development workflow

- **Every new feature needs unit tests.** Whenever we add a new feature (a new
  service method, endpoint, pipeline stage, widget, provider, etc.), add unit
  tests covering it as part of the same change — not just the happy path, but
  edge cases (empty/null inputs, boundary values, error/exception paths,
  concurrent or already-in-a-terminal-state scenarios, etc.). Backend tests go
  under `backend/src/test/java/...` mirroring the package of the code under
  test; frontend tests go under `frontend/test/...` mirroring `lib/`. Treat a
  feature as incomplete until it has test coverage, not as a follow-up task.

## Architecture

### Backend package layout (`backend/src/main/java/com/pickup/`)

Feature-per-package, not layer-per-package: each domain area (`event`, `trip`,
`participant`, `contact`, `vehicle`, `user`, `auth`, `notification`, `location`,
`tripstop`) holds its own entity, repository, service, controller, and `dto/`
subpackage together. Cross-cutting code lives in `common/` (API envelope,
exceptions, enums, geo utilities) and `config/`/`security/` (Spring Security,
JWT, WebSocket wiring).

Key architectural threads that span multiple files:

- **API envelope**: every controller returns `ApiResponse<T>`
  (`common/api/ApiResponse.java`), and `GlobalExceptionHandler`
  (`common/exception/`) converts thrown `BaseException` subclasses
  (`NotFoundException`, `ConflictException`, `ForbiddenException`, etc.) into
  the `ApiError` shape inside that envelope. Throw the typed exception; don't
  build error responses by hand in controllers.
- **Auth**: stateless JWT via `security/JwtAuthenticationFilter` +
  `JwtTokenProvider`. `SecurityConfig` permits `/api/v1/auth/**`, `/ws/**`,
  `/actuator/health`, and (only when `pickup.dev.enabled`) `/api/v1/dev/**`;
  everything else requires an authenticated principal. `@CurrentUser` resolves
  the authenticated organizer's id in controllers.
- **Auto-assignment pipeline** (event/planning + event/assignment +
  common/geo/routing): `AutoAssignmentService.generate()` orchestrates the
  whole flow — it loads eligible drivers/passengers (must be in an assignable
  `ParticipantStatus`, drivers need a vehicle, passengers need a complete
  pickup location), excludes anything locked by `AssignmentPreservation`
  (participants already on an in-flight trip that shouldn't be reshuffled),
  runs `DriverPassengerScorer.assign()` to match passengers to drivers by
  proximity, then `StopOrderPlanner.orderPassengerIds()` to sequence each
  driver's stops, and finally hands the plan to `AssignmentService.submit()`
  for persistence. Distance/duration estimates for both scoring and ordering
  flow through `RouteEstimateService`, which delegates to either
  `GoogleRoutesTravelProvider` (when `pickup.google.routes.enabled=true`) or
  `HaversineTravelProvider` as a fallback — read `RouteEstimateService` before
  touching anything distance-related, since scorer/planner never call a
  provider directly.
- **Trip navigation**: `TripNavigationResolver` +
  `GoogleMapsNavigationUrlBuilder` build deep links for the driver's
  step-by-step flow; `TripRouteEnrichmentService` attaches route
  estimates to trip/stop DTOs after trips are generated.
- **State machines**: `ParticipantStatus`, `TripStatus`, and `StopStatus`
  (`common/enums/`) describe full lifecycles, but not every transition is
  wired up yet — check the enum's own doc comment and the relevant service
  before assuming a transition is enforced.
- **Migrations**: schema is managed by Flyway
  (`spring.jpa.hibernate.ddl-auto: validate`, never `update`), with SQL files
  in `src/main/resources/db/migration`. Add a new `V{n}__description.sql`
  rather than editing an existing one. A local Postgres volume created before
  a baseline change won't match the new baseline — wipe it with
  `docker compose down -v` (or drop/recreate the local DB).
- **Config profiles**: `application.yml` holds shared/default config;
  `application-local.yml` and `application-docker.yml` override
  datasource/dev-seed settings per profile. `pickup.dev.enabled` /
  `pickup.dev.auto-seed` gate the dev-data endpoints and startup seeding.

### Organizer-first model (read before touching event/participant flows)

There is a single kind of login (organizer). Drivers and passengers are
**Contacts** (`contact/ContactEntity`) owned by an organizer — reusable across
events, with a default pickup address / vehicle — rather than separate user
accounts. An organizer adds Contacts to an event via "Add from People"
(`participant/`), which creates an `EventParticipantEntity` that can be
**Contact-backed** (`contact_id` set, `user_id` null) or, for the legacy
self-join path, **user-backed** (`user_id` set, `contact_id` null); both
`event_participants.user_id` and `trips.driver_id` are nullable to allow this.
Contact-backed participants land as `READY` immediately (no approval step) and
are assignable alongside legacy `CONFIRMED` self-joins. Editing a
Contact-backed participant's per-event role/pickup/vehicle is local to that
event and never writes back to the Contact. Trips generated for a
Contact-only driver have no user login to authenticate as, so organizers
monitor those trips rather than the driver executing them through the app.

### Frontend layout (`frontend/lib/`)

Feature-based, mirroring the backend's domains: `features/<name>/data/`
(API client + DTOs, one per feature, using `dio`) and
`features/<name>/presentation/` (screens/widgets, Riverpod for state). Shared
infrastructure lives in `core/` (`ApiClient`/`dio` setup with auth header +
401 interceptor in `core/network/api_client.dart`, secure token storage,
`go_router` config in `core/router/`) and `shared/` (cross-feature providers
like `auth_provider.dart`).

- Routing: all paths are centralized in `core/router/route_paths.dart`;
  `app_router.dart` wires them to screens. Add new routes there rather than
  hardcoding path strings in screens.
- API base URL is compile-time via `--dart-define=PICKUP_API_BASE_URL=...`
  (defaults to `http://localhost:8080`); the dio client appends `/api/v1`.
- On a 401 (except from `/auth/**`), the dio interceptor calls
  `UnauthorizedNotifier`, which `AuthController` subscribes to in order to
  clear stored tokens and redirect to `/login` — don't add ad-hoc 401 handling
  in individual feature API clients.
