package com.pickup.common.enums;

/**
 * Full lifecycle of an EventParticipant.
 * Phase 1 only declares these values; transitions are enforced in a later phase.
 */
public enum ParticipantStatus {
    INVITED,
    REQUESTED,
    APPROVED,
    REJECTED,
    CONFIRMED,
    ASSIGNED,
    CHECKED_IN,
    PICKED_UP,
    ARRIVED,
    CANCELLED,
    NO_SHOW
}
