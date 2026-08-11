package com.pickup.common.enums;

/**
 * Full lifecycle of an EventParticipant.
 * Phase 1 only declares these values; transitions are enforced in a later phase.
 *
 * <p>{@link #READY} was added in Phase 4D-1 for the organizer-first workflow:
 * a Contact-backed participant added directly by the organizer becomes READY
 * immediately (no self-join / approval / confirmation). It is not yet written
 * anywhere until Phase 4D-2 wires up Contact-to-EventParticipant creation.
 * The legacy statuses above it remain for the self-join flow, which stays
 * compiling but is no longer the primary product surface.</p>
 */
public enum ParticipantStatus {
    INVITED,
    REQUESTED,
    APPROVED,
    REJECTED,
    CONFIRMED,
    READY,
    ASSIGNED,
    CHECKED_IN,
    PICKED_UP,
    ARRIVED,
    CANCELLED,
    NO_SHOW
}
