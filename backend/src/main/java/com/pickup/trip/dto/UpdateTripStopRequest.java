package com.pickup.trip.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Driver-issued action against the currently-active stop of a trip.
 *
 * <p>Phase 3B exposes three transitions out of {@code ACTIVE}:
 * <ul>
 *   <li>{@link StopAction#PICK_UP} — passenger picked up, stop -> {@code PICKED_UP}.</li>
 *   <li>{@link StopAction#SKIP}    — passenger no-show, stop -> {@code SKIPPED}.</li>
 *   <li>{@link StopAction#CANCEL}  — driver cancels this stop, stop -> {@code CANCELLED}.</li>
 * </ul>
 */
public record UpdateTripStopRequest(
        @NotNull StopAction action
) {
    public enum StopAction {
        PICK_UP,
        SKIP,
        CANCEL
    }
}
