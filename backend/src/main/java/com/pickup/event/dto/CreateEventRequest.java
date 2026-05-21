package com.pickup.event.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public record CreateEventRequest(
        @NotBlank @Size(max = 200) String title,
        @Size(max = 4000) String description,
        @NotBlank @Size(max = 500) String destinationAddress,
        @NotNull @DecimalMin("-90") @DecimalMax("90") Double destinationLat,
        @NotNull @DecimalMin("-180") @DecimalMax("180") Double destinationLng,
        @NotNull @Future Instant eventTime
) {}
