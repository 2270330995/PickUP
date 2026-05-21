package com.pickup.common.enums;

/**
 * Per-event role a user takes in a specific event.
 * A single user can hold different ParticipantRole values across events.
 */
public enum ParticipantRole {
    ORGANIZER,
    DRIVER,
    PASSENGER,
    INDEPENDENT_ATTENDEE
}
