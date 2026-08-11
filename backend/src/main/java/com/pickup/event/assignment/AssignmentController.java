package com.pickup.event.assignment;

import com.pickup.common.api.ApiResponse;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.event.assignment.dto.SubmitAssignmentsRequest;
import com.pickup.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events/{eventId}/assignments")
public class AssignmentController {

    private final AssignmentService assignmentService;

    public AssignmentController(AssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    /**
     * Organizer-only: atomically replace the event's manual assignment plan.
     * Prior trips are deleted and rebuilt from the submitted payload. Returns
     * the freshly created trips plus the list of unassigned confirmed passengers.
     */
    @PostMapping
    public ApiResponse<AssignmentPlanResponse> submit(@PathVariable UUID eventId,
                                                       @Valid @RequestBody SubmitAssignmentsRequest request) {
        return ApiResponse.ok(assignmentService.submit(
                CurrentUser.require().getId(), eventId, request));
    }
}
