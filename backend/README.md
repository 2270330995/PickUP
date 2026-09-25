# backend

The Pick Up! backend: a Spring Boot 3 (Java 21) API server for the organizer-run
carpool coordination app described in the repo root `CLAUDE.md`. It exposes a
JWT-authenticated REST API (envelope: `common/api/ApiResponse`), backed by
Postgres via Spring Data JPA with Flyway-managed schema.

## Building and running

See the root `CLAUDE.md`'s "Commands" section for the full set of commands
(`./mvnw spring-boot:run`, `./mvnw test`, `./mvnw package`, Docker Compose, dev
seeding). In short: Postgres must be running (`docker compose up postgres -d`
from the repo root), then `./mvnw spring-boot:run` starts the API on `:8080`
under the `local` profile.

- `pom.xml` — Maven build: Spring Boot 3.3.4 parent, Java 21. Key dependencies:
  `spring-boot-starter-web`/`-validation`/`-data-jpa`/`-security`/`-websocket`,
  `postgresql` driver, `flyway-core` + `flyway-database-postgresql`, `jjwt`
  (JWT), Lombok, Actuator, `spring-boot-devtools`, and
  `spring-boot-starter-test` + `spring-security-test` for tests.
- `Dockerfile` / `.dockerignore` — container build, used by the repo-root
  `docker-compose.yml`.
- `mvnw` / `mvnw.cmd` / `.mvn/` — Maven wrapper (not documented further; generated
  tooling).

## Directory map

- `src/main/java/com/pickup/` — [application source](src/main/java/com/pickup/README.md),
  organized feature-per-package.
- `src/main/resources/` — `application.yml` (shared config) plus
  `application-local.yml`/`application-docker.yml` (profile overrides for
  datasource/dev-seed settings — see root `CLAUDE.md`'s "Config profiles"), and
  [`db/migration/`](src/main/resources/db/migration/README.md) (Flyway SQL).
- `src/test/java/com/pickup/` — unit tests, mirroring the main package layout for
  the packages that have test coverage (see each subpackage's own README).
