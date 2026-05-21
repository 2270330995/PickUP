package com.pickup.common.enums;

/**
 * Trip execution status. Supports the step-by-step driver flow
 * (waiting for next stop, all passengers picked, heading to destination).
 */
public enum TripStatus {
    ASSIGNED,
    STARTED,
    IN_PROGRESS,
    WAITING_FOR_NEXT_STOP,
    ALL_PASSENGERS_PICKED,
    HEADING_TO_DESTINATION,
    COMPLETED,
    INTERRUPTED
}
