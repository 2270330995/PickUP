package com.pickup.event.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public record UpdateEventRequest(
        @Size(min = 1, max = 200) String title,
        @Size(max = 4000) String description,
        @Size(min = 1, max = 500) String destinationAddress,
        @DecimalMin("-90") @DecimalMax("90") Double destinationLat,
        @DecimalMin("-180") @DecimalMax("180") Double destinationLng,
        @Future Instant eventTime
) {}
