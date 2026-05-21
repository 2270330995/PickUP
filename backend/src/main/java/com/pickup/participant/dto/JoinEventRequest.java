package com.pickup.participant.dto;

import com.pickup.common.enums.ParticipantRole;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Self-join payload. {@code role} must be one of DRIVER, PASSENGER, INDEPENDENT_ATTENDEE
 * (ORGANIZER is rejected by the service since organizers are created automatically).
 */
public record JoinEventRequest(
        @NotNull ParticipantRole role,
        @Size(max = 500) String pickupAddress,
        @DecimalMin("-90") @DecimalMax("90") Double pickupLat,
        @DecimalMin("-180") @DecimalMax("180") Double pickupLng
) {}
