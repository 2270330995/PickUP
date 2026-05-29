package com.pickup.trip;

import com.pickup.common.api.ApiResponse;
import com.pickup.event.assignment.AssignmentService;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.security.CurrentUser;
import com.pickup.trip.dto.TripResponse;
import com.pickup.trip.dto.UpdateTripStopRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class TripController {

    private final TripService tripService;
    private final TripExecutionService tripExecutionService;
    private final AssignmentService assignmentService;

    public TripController(TripService tripService,
                          TripExecutionService tripExecutionService,
                          AssignmentService assignmentService) {
        this.tripService = tripService;
        this.tripExecutionService = tripExecutionService;
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

    /** Driver starts the trip: ASSIGNED -> IN_PROGRESS + first stop activated. */
    @PostMapping("/trips/{tripId}/start")
    public ApiResponse<TripResponse> start(@PathVariable UUID tripId) {
        return ApiResponse.ok(tripExecutionService.start(tripId, CurrentUser.require().getId()));
    }

    /** Driver completes the trip: ALL_PASSENGERS_PICKED -> COMPLETED. */
    @PostMapping("/trips/{tripId}/complete")
    public ApiResponse<TripResponse> complete(@PathVariable UUID tripId) {
        return ApiResponse.ok(tripExecutionService.complete(tripId, CurrentUser.require().getId()));
    }

    /**
     * Driver resolves the current ACTIVE stop with one of PICK_UP / SKIP / CANCEL.
     * Returns the freshly mutated trip so the client renders the next state without
     * an extra round-trip.
     */
    @PatchMapping("/trips/{tripId}/stops/{stopId}")
    public ApiResponse<TripResponse> updateStop(@PathVariable UUID tripId,
                                                @PathVariable UUID stopId,
                                                @Valid @RequestBody UpdateTripStopRequest request) {
        return ApiResponse.ok(tripExecutionService.updateStop(
                tripId, stopId, CurrentUser.require().getId(), request));
    }
}
