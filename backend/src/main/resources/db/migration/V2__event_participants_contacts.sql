-- Phase 4D-2: contact-backed event participants + trip driver participant FK

-- event_participants: optional user OR contact (exactly one)
ALTER TABLE event_participants
    ADD COLUMN contact_id UUID,
    ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE event_participants
    ADD CONSTRAINT fk_participants_contact
        FOREIGN KEY (contact_id) REFERENCES contacts (id);

ALTER TABLE event_participants
    DROP CONSTRAINT uk_event_participants_event_user;

CREATE UNIQUE INDEX uk_event_participants_event_user
    ON event_participants (event_id, user_id)
    WHERE user_id IS NOT NULL;

CREATE UNIQUE INDEX uk_event_participants_event_contact
    ON event_participants (event_id, contact_id)
    WHERE contact_id IS NOT NULL;

ALTER TABLE event_participants
    ADD CONSTRAINT chk_participants_user_xor_contact
        CHECK (
            (user_id IS NOT NULL AND contact_id IS NULL)
            OR (user_id IS NULL AND contact_id IS NOT NULL)
        );

CREATE INDEX idx_participants_contact_id ON event_participants (contact_id);

-- trips: driver may be a user (legacy) or an event participant (contact-backed)
ALTER TABLE trips
    ADD COLUMN driver_participant_id UUID,
    ALTER COLUMN driver_id DROP NOT NULL;

ALTER TABLE trips
    ADD CONSTRAINT fk_trips_driver_participant
        FOREIGN KEY (driver_participant_id) REFERENCES event_participants (id);

ALTER TABLE trips
    ADD CONSTRAINT chk_trips_driver_ref
        CHECK (driver_id IS NOT NULL OR driver_participant_id IS NOT NULL);

CREATE INDEX idx_trips_driver_participant_id ON trips (driver_participant_id);
