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

### Demo account

PickUP is now an **organizer-first** tool (Phase 4D-1): there is a single login, and drivers/passengers are reusable **People (Contacts)** owned by that organizer rather than separate user accounts.

| Email | Role |
|-------|------|
| `john@test.com` | Organizer (password **`test`**) |

Signing in as John seeds a People roster you can browse under **People**:

| Contact | Preferred role | Vehicle |
|---------|-----------------|---------|
| Jack | Driver | Toyota Corolla (default start: Van Ness Ave) |
| Jacob | Driver | Honda Civic (default start: Geary Blvd) |
| Dell, James, Emma, Noah, Olivia, Liam | Passenger | Default pickup address set |

A **PickUP Demo Event** is also created for John to organize, with all 8 Contacts already added as **READY** participants (Phase 4D-2) — drivers carry their seeded vehicle, passengers carry their default pickup address — so you can jump straight to **Assign** and generate trips without walking through the "Add from People" flow first.

### People → Event → Assign (Phase 4D-2)

Organizers add participants to an event straight from their People roster instead of waiting for self-service join requests:

1. **People** — maintain a reusable roster of Contacts (with default pickup address / vehicle) under **People**.
2. **Add to Event** — from an event's Participants section, use **Add from People** to multi-select Contacts, assign each a per-event role, and (for drivers) pick a vehicle. They land as **READY** immediately — no approval step.
3. **Assign** — run manual or auto-assignment as usual; READY participants are eligible alongside legacy CONFIRMED self-joins. A DRIVER may be added without a vehicle, but assignment rejects them until one is set (the event screen shows a "vehicle required" warning).
4. **Trips** — generated trips show the Contact's name even though it has no user login; driver-facing execution/authentication for Contact-only drivers is deferred to a later phase, so organizers monitor these trips instead.

Editing a Contact-backed participant's per-event role, pickup, or vehicle from the event screen never writes back to the underlying Contact — those changes stay local to that event.

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
- Database migrations (Hibernate `ddl-auto=update` until Phase 4D-1 introduced Flyway; see below).

## Database migrations (Flyway)

Since Phase 4D-1, schema changes are managed by **Flyway** (`spring.jpa.hibernate.ddl-auto: validate`) with migrations in `backend/src/main/resources/db/migration`. Phase 4D-2 adds `V2__event_participants_contacts.sql`, which makes `event_participants.user_id` and `trips.driver_id` nullable and adds `contact_id` / `driver_participant_id` so Contacts can be added to events directly. If you have an existing local database from before Phase 4D-1 (or 4D-2), it won't match the new baseline — wipe it and let Flyway recreate everything from scratch:

```bash
docker compose down -v && docker compose up --build
```

(or drop/recreate your local `pickup` Postgres database if running the backend without Docker).
