package com.pickup.contact;

import com.pickup.common.api.ApiResponse;
import com.pickup.security.CurrentUser;
import com.pickup.vehicle.VehicleService;
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

/** Reusable vehicle records owned by an organizer's Contact (Phase 4D-1). */
@RestController
@RequestMapping("/api/v1/contacts/{contactId}/vehicles")
public class ContactVehicleController {

    private final VehicleService vehicleService;

    public ContactVehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping
    public ApiResponse<List<VehicleResponse>> list(@PathVariable UUID contactId) {
        return ApiResponse.ok(vehicleService.listForContact(CurrentUser.require().getId(), contactId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<VehicleResponse> create(@PathVariable UUID contactId,
                                               @Valid @RequestBody CreateVehicleRequest request) {
        return ApiResponse.ok(
                vehicleService.createForContact(CurrentUser.require().getId(), contactId, request));
    }

    @PatchMapping("/{vehicleId}")
    public ApiResponse<VehicleResponse> update(@PathVariable UUID contactId,
                                               @PathVariable UUID vehicleId,
                                               @Valid @RequestBody UpdateVehicleRequest request) {
        return ApiResponse.ok(
                vehicleService.updateVehicle(CurrentUser.require().getId(), contactId, vehicleId, request));
    }

    @DeleteMapping("/{vehicleId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID contactId, @PathVariable UUID vehicleId) {
        vehicleService.deleteVehicle(CurrentUser.require().getId(), contactId, vehicleId);
    }
}
