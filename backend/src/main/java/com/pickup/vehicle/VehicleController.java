package com.pickup.vehicle;

import com.pickup.common.api.ApiResponse;
import com.pickup.security.CurrentUser;
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

@RestController
@RequestMapping("/api/v1/vehicles")
public class VehicleController {

    private final VehicleService vehicleService;

    public VehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping
    public ApiResponse<List<VehicleResponse>> list() {
        return ApiResponse.ok(vehicleService.listMyVehicles(CurrentUser.require().getId()));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<VehicleResponse> create(@Valid @RequestBody CreateVehicleRequest request) {
        return ApiResponse.ok(vehicleService.createVehicle(CurrentUser.require().getId(), request));
    }

    @PatchMapping("/{id}")
    public ApiResponse<VehicleResponse> update(@PathVariable UUID id,
                                               @Valid @RequestBody UpdateVehicleRequest request) {
        return ApiResponse.ok(vehicleService.updateVehicle(CurrentUser.require().getId(), id, request));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        vehicleService.deleteVehicle(CurrentUser.require().getId(), id);
    }
}
