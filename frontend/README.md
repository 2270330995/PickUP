# Pick Up! — Frontend

Flutter client for **Pick Up!**, a mobile-first carpool app for events. An
organizer manages a reusable roster of Contacts (drivers/passengers who don't
need their own login), adds them to events, and runs auto-assignment to
build trips with ordered pickup stops. This app talks to the Spring Boot
backend in `../backend`. See the repo's top-level `CLAUDE.md` for the full
product/architecture overview, including the "organizer-first model" that
shapes most of the participant/event code here.

## Requirements

- Flutter SDK `>=3.22.0`, Dart `>=3.4.0` (see `pubspec.yaml`).
- A running backend to point the app at (see `../backend`'s README/CLAUDE.md,
  or `docker compose up --build` from the repo root).

## Getting started

```bash
flutter pub get
```

Platform shells (`android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`)
are regenerated with `flutter create .` if missing or need updating — this
preserves everything under `lib/`.

### Run against a backend

The dio client's base URL is compile-time, via `--dart-define`:

```bash
# Android emulator (backend on host machine)
flutter run --dart-define=PICKUP_API_BASE_URL=http://10.0.2.2:8080

# iOS simulator / desktop
flutter run --dart-define=PICKUP_API_BASE_URL=http://localhost:8080
```

It defaults to `http://localhost:8080` if omitted (see
`lib/core/network/api_client.dart`). Demo login (after seeding the backend,
see its dev-seed endpoint): `john@test.com` / `test`.

To enable Google Places address autocomplete (`features/location`), also
pass `--dart-define=GOOGLE_PLACES_API_KEY=your-key`; without it, address
fields fall back to manual address/latitude/longitude entry.

### Tests and lint

```bash
flutter test                                    # all tests
flutter test test/path/to/some_test.dart        # single file
flutter analyze                                 # lint
```

See [`test/README.md`](test/README.md) — the current test suite is just the
unmodified Flutter counter-app boilerplate and does not yet cover this app.

## Directory map

- [`lib/`](lib/README.md) — all app source: `core/` (shared infrastructure),
  `features/` (one package per product capability), `shared/` (cross-feature
  state).
- [`test/`](test/README.md) — test suite (currently stale boilerplate; see
  its README).
- `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` — Flutter-
  generated platform shells/scaffolding, not hand-written project code.
- `pubspec.yaml` — dependencies: `flutter_riverpod` (state), `go_router`
  (routing), `dio` (HTTP), `flutter_secure_storage`/`shared_preferences`
  (token storage), `freezed`/`json_serializable` (codegen, where used),
  `url_launcher` (navigation deep links), `uuid` (Places session tokens).
