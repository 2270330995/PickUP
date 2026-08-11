package com.pickup.vehicle.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateVehicleRequest(
        @Size(max = 60) String label,
        @NotBlank @Size(max = 80) String make,
        @NotBlank @Size(max = 80) String model,
        @Size(max = 40) String color,
        @Size(max = 20) String plate,
        @Min(1) @Max(15) int seats,
        @Size(max = 2000) String notes
) {}
