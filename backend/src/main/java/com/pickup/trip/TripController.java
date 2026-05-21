package com.pickup.trip;

import com.pickup.common.api.ApiResponse;
import com.pickup.common.api.NotImplemented;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class TripController {

    @GetMapping("/events/{eventId}/trips")
    public ApiResponse<Void> listForEvent(@PathVariable UUID eventId) {
        return NotImplemented.phase1("GET /api/v1/events/{eventId}/trips");
    }

    @GetMapping("/trips/{tripId}")
    public ApiResponse<Void> get(@PathVariable UUID tripId) {
        return NotImplemented.phase1("GET /api/v1/trips/{tripId}");
    }

    @PostMapping("/trips/{tripId}/start")
    public ApiResponse<Void> start(@PathVariable UUID tripId) {
        return NotImplemented.phase1("POST /api/v1/trips/{tripId}/start");
    }

    @PostMapping("/trips/{tripId}/complete")
    public ApiResponse<Void> complete(@PathVariable UUID tripId) {
        return NotImplemented.phase1("POST /api/v1/trips/{tripId}/complete");
    }

    @PatchMapping("/trips/{tripId}/stops/{stopId}")
    public ApiResponse<Void> updateStop(@PathVariable UUID tripId, @PathVariable UUID stopId) {
        return NotImplemented.phase1("PATCH /api/v1/trips/{tripId}/stops/{stopId}");
    }
}
