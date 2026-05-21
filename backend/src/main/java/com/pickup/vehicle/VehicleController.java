package com.pickup.vehicle;

import com.pickup.common.api.ApiResponse;
import com.pickup.common.api.NotImplemented;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/vehicles")
public class VehicleController {

    @GetMapping
    public ApiResponse<Void> list() {
        return NotImplemented.phase1("GET /api/v1/vehicles");
    }

    @PostMapping
    public ApiResponse<Void> create() {
        return NotImplemented.phase1("POST /api/v1/vehicles");
    }

    @PatchMapping("/{id}")
    public ApiResponse<Void> update(@PathVariable UUID id) {
        return NotImplemented.phase1("PATCH /api/v1/vehicles/{id}");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable UUID id) {
        return NotImplemented.phase1("DELETE /api/v1/vehicles/{id}");
    }
}
