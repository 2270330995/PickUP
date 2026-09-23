# Pick Up!

Mobile-first carpool app for events. An **organizer** maintains a reusable roster of **Contacts** (drivers/passengers, no login of their own), adds them to **Events**, and runs **auto-assignment** to build **Trips** with ordered pickup stops.

---

## Tech stack

| Layer         | Choice                                                                |
| ------------- | ---------------------------------------------------------------------- |
| Frontend      | Flutter (Dart ≥ 3.4) + Riverpod + go_router + dio + flutter_secure_storage |
| Backend       | Spring Boot 3.3 (Java 21, Maven)                                      |
| Security      | Spring Security — stateless JWT                                       |
| Realtime      | Spring WebSocket (STOMP, `/ws`)                                       |
| Persistence   | JPA / Hibernate + PostgreSQL 16, schema managed by Flyway              |
| Routing/geo   | Google Routes API (optional) with a Haversine fallback                 |
| Deployment    | Docker (`backend/Dockerfile` + root `docker-compose.yml`)              |

---

## Repository layout

```
PickUP/
├── backend/                 # Spring Boot service (feature-per-package: event, trip,
│                             #   participant, contact, vehicle, user, auth, notification,
│                             #   location, tripstop; cross-cutting code in common/, config/, security/)
├── frontend/                # Flutter app (feature-based: features/<name>/data + presentation,
│                             #   shared infra in core/ and shared/)
├── docker-compose.yml       # Postgres + backend
├── .env.example
└── README.md
```

See [CLAUDE.md](CLAUDE.md) for a detailed architecture walkthrough, including the auto-assignment pipeline, the organizer-first data model, and the state machines behind participants/trips/stops.

---

## Prerequisites

- **Docker Desktop** (or Docker Engine + Compose v2)
- **JDK 21** (only needed for running the backend outside Docker)
- **Flutter ≥ 3.22** with Dart ≥ 3.4

---

## Running the full stack with Docker

```bash
cp .env.example .env
docker compose up --build
```

Then:
- Backend → `http://localhost:8080`
- Postgres → `localhost:5432` (db `pickup`, user/pass from `.env`)
- Health → `http://localhost:8080/actuator/health`

To stop and wipe data (needed after a Flyway baseline change):

```bash
docker compose down -v
```

## Running the backend locally (no Docker)

Start only Postgres from compose (the easiest option — no local install needed):

```bash
cp .env.example .env
docker compose up postgres -d
```

Then run the backend with the `local` Spring profile (the default):

```bash
cd backend
./mvnw spring-boot:run
```

The `local` profile connects to `localhost:5432/pickup` with user/password `pickup/pickup`.

### Backend commands

```bash
./mvnw spring-boot:run                                # run locally
./mvnw test                                            # run all tests
./mvnw test -Dtest=AssignmentServiceTest               # single test class
./mvnw test -Dtest=AssignmentServiceTest#methodName    # single test method
./mvnw package                                         # build jar
```

---

## Running the Flutter app

Install Flutter once, then on first run generate the platform shells (this only adds `android/`, `ios/`, `web/` etc. — `lib/` is preserved):

```bash
cd frontend
flutter pub get
```

```bash
# Android emulator (10.0.2.2 maps to the host machine)
flutter run --dart-define=PICKUP_API_BASE_URL=http://10.0.2.2:8080

# iOS simulator / desktop
flutter run --dart-define=PICKUP_API_BASE_URL=http://localhost:8080
```

### Frontend commands

```bash
flutter pub get
flutter test                                    # all tests
flutter test test/path/to/some_test.dart        # single file
flutter analyze                                 # lint
```

---

## Demo data

The backend can auto-create a full test scenario so you don't have to register accounts manually. On a fresh database (`docker compose down -v && docker compose up --build`), demo data is seeded automatically at startup.

| Email            | Role                          |
| ---------------- | ------------------------------ |
| `john@test.com`  | Organizer (password **`test`**) |

Signing in as John seeds a People roster (drivers with vehicles, passengers with default pickup addresses) plus a demo event with all Contacts already added as `READY` participants, so you can jump straight to **Assign** and generate trips.

Re-seed or inspect demo accounts manually:

```bash
curl -X POST http://localhost:8080/api/v1/dev/seed
curl http://localhost:8080/api/v1/dev/accounts
```

Dev endpoints (`/api/v1/dev/**`) are enabled only in the `local` and `docker` Spring profiles. In Flutter debug builds, the sign-in screen also shows a **Dev testing** section with quick-login buttons for each seeded account.

---

## How it works

Pick Up! is organizer-first: there is a single kind of login (the organizer). Drivers and passengers are **Contacts** — reusable across events, each with a default pickup address / vehicle — rather than separate user accounts. Organizers add Contacts to an event via "Add from People," which lands them as `READY` participants immediately (no approval step needed).

Running auto-assignment (`AutoAssignmentService`) loads eligible drivers/passengers, matches passengers to drivers by proximity (`DriverPassengerScorer`), sequences each driver's stops (`StopOrderPlanner`), and persists the result as Trips with ordered pickup stops. Distance and duration estimates flow through `RouteEstimateService`, which uses the Google Routes API when configured or falls back to Haversine distance otherwise.

Schema changes are managed by Flyway (`backend/src/main/resources/db/migration`); every controller response is wrapped in a common `ApiResponse<T>` envelope with typed exceptions mapped to structured API errors.

---

## License

No license file is currently included in this repository.

---
> README maintained automatically by [🐘 elephant](https://github.com/tonone-ai/elephant) — keep your docs in sync without the manual work.
