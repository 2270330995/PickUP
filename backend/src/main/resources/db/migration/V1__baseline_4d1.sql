-- Phase 4D-1 baseline schema.
--
-- Local/dev data is not preserved across this migration (see README). This single
-- migration creates the full schema as of Phase 4D-1: the pre-existing tables
-- (mirroring today's JPA entities) plus the new organizer-owned `contacts` table
-- and the ownership move of `vehicles` from users to contacts.
--
-- IDs are UUIDs generated application-side (Hibernate), so no DB-side defaults
-- are needed on primary keys.

-- ─────────────────────────────────────────────────────────────────────────────
-- users
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE users (
    id              UUID PRIMARY KEY,
    email           VARCHAR(255) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    phone           VARCHAR(255),
    fcm_token       VARCHAR(255),
    created_at      TIMESTAMPTZ NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_users_email UNIQUE (email)
);

CREATE TABLE user_system_roles (
    user_id UUID NOT NULL REFERENCES users (id),
    role    VARCHAR(255) NOT NULL,
    CONSTRAINT uk_user_system_role UNIQUE (user_id, role)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- events
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE events (
    id                     UUID PRIMARY KEY,
    organizer_id           UUID NOT NULL,
    title                  VARCHAR(255) NOT NULL,
    description            TEXT,
    destination_address    VARCHAR(255) NOT NULL,
    destination_lat        DOUBLE PRECISION NOT NULL,
    destination_lng        DOUBLE PRECISION NOT NULL,
    event_time             TIMESTAMPTZ NOT NULL,
    status                 VARCHAR(32) NOT NULL,
    planning_status        VARCHAR(32) NOT NULL,
    assignment_generated   BOOLEAN NOT NULL,
    created_at             TIMESTAMPTZ NOT NULL,
    updated_at             TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id) REFERENCES users (id)
);

CREATE INDEX idx_events_organizer_id ON events (organizer_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- contacts (Phase 4D-1: organizer-owned people roster)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE contacts (
    id                  UUID PRIMARY KEY,
    organizer_id        UUID NOT NULL,
    name                VARCHAR(120) NOT NULL,
    phone               VARCHAR(40),
    email               VARCHAR(160),
    default_address     VARCHAR(240),
    default_lat         DOUBLE PRECISION,
    default_lng         DOUBLE PRECISION,
    notes               TEXT,
    preferred_role      VARCHAR(32),
    claimed_by_user_id  UUID,
    archived_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_contacts_organizer FOREIGN KEY (organizer_id) REFERENCES users (id),
    CONSTRAINT fk_contacts_claimed_by_user FOREIGN KEY (claimed_by_user_id) REFERENCES users (id)
);

CREATE INDEX idx_contacts_organizer_id ON contacts (organizer_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- vehicles (Phase 4D-1: ownership moved from users to contacts)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE vehicles (
    id          UUID PRIMARY KEY,
    contact_id  UUID NOT NULL,
    label       VARCHAR(60),
    make        VARCHAR(80) NOT NULL,
    model       VARCHAR(80) NOT NULL,
    color       VARCHAR(40),
    plate       VARCHAR(20),
    seats       INTEGER NOT NULL,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_vehicles_contact FOREIGN KEY (contact_id) REFERENCES contacts (id)
);

CREATE INDEX idx_vehicles_contact_id ON vehicles (contact_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- event_participants (unchanged in 4D-1: user_id remains required)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE event_participants (
    id              UUID PRIMARY KEY,
    event_id        UUID NOT NULL,
    user_id         UUID NOT NULL,
    role            VARCHAR(32) NOT NULL,
    status          VARCHAR(32) NOT NULL,
    pickup_address  VARCHAR(255),
    pickup_lat      DOUBLE PRECISION,
    pickup_lng      DOUBLE PRECISION,
    vehicle_id      UUID,
    created_at      TIMESTAMPTZ NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_participants_event FOREIGN KEY (event_id) REFERENCES events (id),
    CONSTRAINT fk_participants_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_participants_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
    CONSTRAINT uk_event_participants_event_user UNIQUE (event_id, user_id)
);

CREATE INDEX idx_participants_event_id ON event_participants (event_id);
CREATE INDEX idx_participants_user_id ON event_participants (user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- trips (unchanged in 4D-1: driver_id still references users)
--
-- trips.current_stop_id and trip_stops.trip_id are mutually referential, so the
-- FK from trips to trip_stops is added after trip_stops exists (see below).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE trips (
    id                          UUID PRIMARY KEY,
    event_id                    UUID NOT NULL,
    driver_id                   UUID NOT NULL,
    vehicle_id                  UUID NOT NULL,
    status                      VARCHAR(40) NOT NULL,
    current_stop_id             UUID,
    final_destination_address  VARCHAR(255) NOT NULL,
    final_destination_lat      DOUBLE PRECISION NOT NULL,
    final_destination_lng      DOUBLE PRECISION NOT NULL,
    encoded_polyline            TEXT,
    started_at                  TIMESTAMPTZ,
    completed_at                 TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ NOT NULL,
    updated_at                  TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_trips_event FOREIGN KEY (event_id) REFERENCES events (id),
    CONSTRAINT fk_trips_driver FOREIGN KEY (driver_id) REFERENCES users (id),
    CONSTRAINT fk_trips_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
);

CREATE INDEX idx_trips_event_id ON trips (event_id);
CREATE INDEX idx_trips_driver_id ON trips (driver_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- trip_stops (unchanged in 4D-1)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE trip_stops (
    id                      UUID PRIMARY KEY,
    trip_id                 UUID NOT NULL,
    participant_id          UUID NOT NULL,
    sequence                INTEGER NOT NULL,
    address                 VARCHAR(255) NOT NULL,
    meeting_point_name      VARCHAR(255),
    lat                     DOUBLE PRECISION NOT NULL,
    lng                     DOUBLE PRECISION NOT NULL,
    status                  VARCHAR(32) NOT NULL,
    eta_minutes             INTEGER,
    actual_arrival_time     TIMESTAMPTZ,
    actual_departure_time   TIMESTAMPTZ,
    navigation_link         TEXT,
    created_at              TIMESTAMPTZ NOT NULL,
    updated_at              TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_trip_stops_trip FOREIGN KEY (trip_id) REFERENCES trips (id),
    CONSTRAINT fk_trip_stops_participant FOREIGN KEY (participant_id) REFERENCES event_participants (id),
    CONSTRAINT uk_trip_stops_trip_sequence UNIQUE (trip_id, sequence)
);

CREATE INDEX idx_trip_stops_trip_id ON trip_stops (trip_id);
CREATE INDEX idx_trip_stops_participant_id ON trip_stops (participant_id);

ALTER TABLE trips
    ADD CONSTRAINT fk_trips_current_stop FOREIGN KEY (current_stop_id) REFERENCES trip_stops (id);

-- ─────────────────────────────────────────────────────────────────────────────
-- notifications (unchanged in 4D-1)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE notifications (
    id            UUID PRIMARY KEY,
    recipient_id  UUID NOT NULL,
    type          VARCHAR(32) NOT NULL,
    title         VARCHAR(255) NOT NULL,
    body          TEXT NOT NULL,
    payload_json  TEXT,
    read_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_notifications_recipient FOREIGN KEY (recipient_id) REFERENCES users (id)
);

CREATE INDEX idx_notifications_recipient_id ON notifications (recipient_id);
