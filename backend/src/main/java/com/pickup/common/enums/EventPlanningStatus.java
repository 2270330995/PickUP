package com.pickup.common.enums;

/**
 * Auto-assignment / trip-planning progress for an event.
 * Orthogonal to {@link EventStatus}.
 */
public enum EventPlanningStatus {
    NOT_STARTED,
    IN_PROGRESS,
    READY,
    FAILED
}
