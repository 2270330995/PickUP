package com.pickup.common.geo;

/**
 * Placeholder for future meeting-point recommendation logic.
 */
public final class MeetingPointDefaults {

    private MeetingPointDefaults() {}

    /**
     * Phase 4C leaves meeting points unset; pickup address remains the stop location.
     */
    public static java.util.Optional<String> defaultName(String pickupAddress) {
        return java.util.Optional.empty();
    }
}
