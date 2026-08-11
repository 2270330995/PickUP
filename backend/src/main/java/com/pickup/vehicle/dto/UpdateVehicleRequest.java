package com.pickup.vehicle.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

public record UpdateVehicleRequest(
        @Size(max = 60) String label,
        @Size(min = 1, max = 80) String make,
        @Size(min = 1, max = 80) String model,
        @Size(max = 40) String color,
        @Size(max = 20) String plate,
        @Min(1) @Max(15) Integer seats,
        @Size(max = 2000) String notes
) {}
