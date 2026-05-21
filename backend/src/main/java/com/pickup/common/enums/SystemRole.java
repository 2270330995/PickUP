package com.pickup.common.enums;

/**
 * Global platform-level authorization roles.
 *
 * <p>Per-event behavior (organizer / driver / passenger / independent attendee)
 * is intentionally NOT modeled here. See {@link ParticipantRole} on
 * {@code EventParticipant} for event-scoped roles.</p>
 */
public enum SystemRole {
    USER,
    ADMIN
}
