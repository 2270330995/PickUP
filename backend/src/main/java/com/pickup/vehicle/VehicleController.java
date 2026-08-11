package com.pickup.vehicle;

import com.pickup.common.api.ApiResponse;
import com.pickup.common.exception.BadRequestException;
import com.pickup.vehicle.dto.CreateVehicleRequest;
import com.pickup.vehicle.dto.UpdateVehicleRequest;
import com.pickup.vehicle.dto.VehicleResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Legacy user-owned vehicle garage (pre-4D-1). Kept compiling for backward
 * compatibility but no longer functional: vehicles are now owned by organizer
 * Contacts. See {@code com.pickup.contact.ContactVehicleController}.
 */
@RestController
@RequestMapping("/api/v1/vehicles")
public class VehicleController {

    private static final String LEGACY_MESSAGE =
            "Vehicles are now managed under Contacts. Use /api/v1/contacts/{contactId}/vehicles instead.";

    @GetMapping
    public ApiResponse<List<VehicleResponse>> list() {
        throw new BadRequestException(LEGACY_MESSAGE);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<VehicleResponse> create(@Valid @RequestBody CreateVehicleRequest request) {
        throw new BadRequestException(LEGACY_MESSAGE);
    }

    @PatchMapping("/{id}")
    public ApiResponse<VehicleResponse> update(@PathVariable UUID id,
                                               @Valid @RequestBody UpdateVehicleRequest request) {
        throw new BadRequestException(LEGACY_MESSAGE);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        throw new BadRequestException(LEGACY_MESSAGE);
    }
}
