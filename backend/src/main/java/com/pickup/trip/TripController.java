package com.pickup.trip;

import com.pickup.common.api.ApiResponse;
import com.pickup.common.api.NotImplemented;
import com.pickup.event.assignment.AssignmentService;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.security.CurrentUser;
import com.pickup.trip.dto.TripResponse;
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

    private final TripService tripService;
    private final AssignmentService assignmentService;

    public TripController(TripService tripService, AssignmentService assignmentService) {
        this.tripService = tripService;
        this.assignmentService = assignmentService;
    }

    /**
     * Event trip view (organizer or any confirmed/assigned participant).
     * Returns the same shape as {@link AssignmentService#submit} so the organizer
     * UI can render trips and the pool of unassigned passengers in one round-trip.
     */
    @GetMapping("/events/{eventId}/trips")
    public ApiResponse<AssignmentPlanResponse> listForEvent(@PathVariable UUID eventId) {
        return ApiResponse.ok(assignmentService.getPlan(eventId, CurrentUser.require().getId()));
    }

    /** Single-trip read (event organizer, trip driver, or a participant on the trip). */
    @GetMapping("/trips/{tripId}")
    public ApiResponse<TripResponse> get(@PathVariable UUID tripId) {
        return ApiResponse.ok(tripService.getTrip(tripId, CurrentUser.require().getId()));
    }

    // TODO(phase-3b): implement trip start/complete + per-stop status transitions
    //                 (driver-facing execution flow + currentStop updates + timestamps).
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
