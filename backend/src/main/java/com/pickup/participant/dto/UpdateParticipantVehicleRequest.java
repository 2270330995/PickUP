package com.pickup.participant.dto;

import java.util.UUID;

/**
 * PATCH body for a driver participant updating which vehicle they will use for the event.
 * A {@code null} {@code vehicleId} clears the linkage (only allowed before the participant is ASSIGNED).
 */
public record UpdateParticipantVehicleRequest(
        UUID vehicleId
) {}
