package com.pickup.common.enums;

/**
 * Event lifecycle status. Kept intentionally small; planning/assignment
 * progress lives separately on {@link EventPlanningStatus}.
 */
public enum EventStatus {
    DRAFT,
    OPEN,
    CLOSED,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED
}
