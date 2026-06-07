# Pick Up!

Mobile-first carpool app for events — coordinates organizers, drivers, passengers, and independent attendees, with auto-assignment, step-by-step pickup, and reduced manual coordination.

> **Phase 1 status:** architecture-only scaffold. Endpoints return `501 Not Implemented`, screens are placeholders, and there is no real auth, route optimization, Google Maps, FCM, or chat yet. See `.cursor/plans/pickup_phase_1_foundation_*.plan.md` for scope.

---

## Tech stack

| Layer            | Choice                                                             |
| ---------------- | ------------------------------------------------------------------ |
| Frontend         | Flutter + Riverpod + go_router + dio + flutter_secure_storage      |
| Backend          | Spring Boot 3.3 (Java 21, Maven)                                   |
| Security         | Spring Security (stateless JWT skeleton)                           |
| Realtime         | Spring WebSocket (STOMP, `/ws`)                                    |
| Persistence      | JPA / Hibernate + PostgreSQL 16                                    |
| Notifications    | Firebase Cloud Messaging (Phase 2+)                                |
| Maps             | Google Places / Routes / Route Optimization (Phase 3+)             |
| Deployment       | Docker (`backend/Dockerfile` + root `docker-compose.yml`)          |

---

## Repository layout

```
PickUP/
├── backend/                 # Spring Boot service
├── frontend/                # Flutter app
├── docker/                  # scratch dir for compose-level assets
├── docker-compose.yml       # Postgres + backend
├── .env.example
├── .gitignore
└── README.md
```

Detailed structure inside `backend/` and `frontend/lib/` matches the Phase 1 plan.

---

## Prerequisites

- **Docker Desktop** (or Docker Engine + Compose v2)
- **JDK 21** (only needed for running the backend outside Docker)
- **Flutter ≥ 3.22** with Dart ≥ 3.4

---

## Running the backend with Docker

```bash
cp .env.example .env
docker compose up --build
```

Then:
- Backend → `http://localhost:8080`
- Postgres → `localhost:5432` (db `pickup`, user/pass from `.env`)
- Health → `http://localhost:8080/actuator/health`

To stop and wipe data:

```bash
docker compose down -v
```

## Quick testing (demo data)

For local/docker development, the backend can auto-create a full test scenario so you don't have to register accounts manually.

**On a fresh database** (`docker compose down -v && docker compose up --build`), demo data is seeded automatically on startup.

### Demo accounts

All accounts use password **`test`**:

| Email | Role |
|-------|------|
| `john@test.com` | Organizer |
| `jack@test.com` | Driver (Toyota Corolla, trip start: Van Ness Ave) |
| `jacob@test.com` | Driver (Honda Civic, trip start: Geary Blvd) |
| `dell@test.com` | Passenger |
| `james@test.com` | Passenger |
| `emma@test.com` | Passenger |
| `noah@test.com` | Passenger |
| `olivia@test.com` | Passenger |
| `liam@test.com` | Passenger |

The demo event is **PickUP Demo Event** with destination, passenger pickup addresses, driver trip start locations, and vehicles already set up.

### Manual seed / refresh demo

```bash
curl -X POST http://localhost:8080/api/v1/dev/seed
curl http://localhost:8080/api/v1/dev/accounts
```

### Flutter dev panel

When running the app in **debug mode**, the sign-in screen shows a **Dev testing** section with **Load demo data** and quick-login buttons for each account.

Dev endpoints are enabled in the `local` and `docker` Spring profiles only.

## Running the backend locally (no Docker)

Start only Postgres from compose (the easiest option — no local install needed):

```bash
cp .env.example .env
docker compose up postgres -d
```

Then run the backend with the `local` Spring profile:

```bash
cd backend
./mvnw spring-boot:run
```

The `local` profile connects to `localhost:5432/pickup` with user/password `pickup/pickup` (matching the compose defaults). No `SPRING_PROFILES_ACTIVE` override is needed — `local` is the default.

---

## Running the Flutter app

Install Flutter once, then on first run generate the platform shells (this only adds `android/`, `ios/`, `web/` etc. — `lib/` is preserved):

```bash
cd frontend
flutter create .
flutter pub get
```

Run against the Docker-hosted backend:

```bash
# Android emulator (10.0.2.2 maps to the host machine)
flutter run --dart-define=PICKUP_API_BASE_URL=http://10.0.2.2:8080

# iOS simulator / desktop
flutter run --dart-define=PICKUP_API_BASE_URL=http://localhost:8080
```

---

## What's in Phase 1

- Spring Boot 3 + Java 21 + Maven project with profiles (`local`, `docker`).
- Global `ApiResponse<T>` wrapper and `@RestControllerAdvice` exception handler.
- Enums and `BaseEntity` ready for later phases.
- JPA entity skeletons for `User`, `Vehicle`, `Event`, `EventParticipant`, `Trip`, `TripStop`, `Notification`.
- Spring Security skeleton with stateless JWT filter (validation deferred).
- All `/api/v1/*` REST endpoints wired but returning `501 Not Implemented`.
- WebSocket STOMP endpoint registered at `/ws`.
- Flutter app with Riverpod, go_router, Material 3 theme, dio + secure storage, and 7 placeholder screens (splash, login, profile, organizer, event detail, driver trip, passenger ride).
- Dockerfile + docker-compose with healthchecked Postgres.

## Explicitly NOT in Phase 1

- Real auth flow (token issuance / validation / refresh).
- Auto-assignment algorithm and Google Route Optimization integration.
- Google Maps / Places / Routes calls (no deep links yet).
- Firebase Cloud Messaging wiring.
- Chat system.
- State-machine transitions between `ParticipantStatus` / `TripStatus` / `StopStatus`.
- Database migrations (Hibernate `ddl-auto=update` until Phase 2 introduces Flyway).
