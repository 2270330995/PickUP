package com.pickup.participant.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * PATCH body for a passenger participant updating their pickup location for the event.
 */
public record UpdateParticipantPickupRequest(
        @NotBlank @Size(max = 500) String pickupAddress,
        @NotNull @DecimalMin("-90") @DecimalMax("90") Double pickupLat,
        @NotNull @DecimalMin("-180") @DecimalMax("180") Double pickupLng
) {}
