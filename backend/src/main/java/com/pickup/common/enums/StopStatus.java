package com.pickup.common.enums;

/**
 * Per-stop status during trip execution.
 */
public enum StopStatus {
    PENDING,
    ACTIVE,
    NAVIGATING,
    ARRIVED,
    PICKED_UP,
    CANCELLED,
    SKIPPED
}
