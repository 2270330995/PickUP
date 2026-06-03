package com.pickup.event;

import com.pickup.common.api.ApiResponse;
import com.pickup.event.assignment.dto.AssignmentPlanResponse;
import com.pickup.event.dto.CreateEventRequest;
import com.pickup.event.dto.EventDashboardResponse;
import com.pickup.event.dto.EventResponse;
import com.pickup.event.dto.UpdateEventRequest;
import com.pickup.event.planning.AutoAssignmentService;
import com.pickup.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events")
public class EventController {

    private final EventService eventService;
    private final AutoAssignmentService autoAssignmentService;

    public EventController(EventService eventService,
                           AutoAssignmentService autoAssignmentService) {
        this.eventService = eventService;
        this.autoAssignmentService = autoAssignmentService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<EventResponse> create(@Valid @RequestBody CreateEventRequest request) {
        return ApiResponse.ok(eventService.createEvent(CurrentUser.require().getId(), request));
    }

    /**
     * scope=mine -> events I organize (default). scope=open -> joinable events I'm not yet in.
     */
    @GetMapping
    public ApiResponse<List<EventResponse>> list(
            @RequestParam(name = "scope", defaultValue = "mine") String scope) {
        UUID userId = CurrentUser.require().getId();
        List<EventResponse> events = switch (scope) {
            case "open"   -> eventService.listOpenEvents(userId);
            case "mine"   -> eventService.listMyEvents(userId);
            case "joined" -> eventService.listJoinedEvents(userId);
            default -> throw new IllegalArgumentException("Unsupported scope: " + scope);
        };
        return ApiResponse.ok(events);
    }

    @GetMapping("/{id}")
    public ApiResponse<EventResponse> get(@PathVariable UUID id) {
        UUID viewerId = CurrentUser.require().getId();
        return ApiResponse.ok(eventService.getEvent(id, viewerId));
    }

    @PatchMapping("/{id}")
    public ApiResponse<EventResponse> update(@PathVariable UUID id,
                                             @Valid @RequestBody UpdateEventRequest request) {
        return ApiResponse.ok(eventService.updateEvent(CurrentUser.require().getId(), id, request));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        eventService.deleteEvent(CurrentUser.require().getId(), id);
    }

    /** Lifecycle: OPEN -> CLOSED. */
    @PostMapping("/{id}/close")
    public ApiResponse<EventResponse> close(@PathVariable UUID id) {
        return ApiResponse.ok(eventService.closeEvent(CurrentUser.require().getId(), id));
    }

    /** Lifecycle: CLOSED -> OPEN. */
    @PostMapping("/{id}/reopen")
    public ApiResponse<EventResponse> reopen(@PathVariable UUID id) {
        return ApiResponse.ok(eventService.reopenEvent(CurrentUser.require().getId(), id));
    }

    /** Lifecycle: any non-terminal state -> CANCELLED. */
    @PostMapping("/{id}/cancel")
    public ApiResponse<EventResponse> cancel(@PathVariable UUID id) {
        return ApiResponse.ok(eventService.cancelEvent(CurrentUser.require().getId(), id));
    }

    @GetMapping("/{id}/dashboard")
    public ApiResponse<EventDashboardResponse> dashboard(@PathVariable UUID id) {
        CurrentUser.require();
        return ApiResponse.ok(eventService.getEventDashboard(id));
    }

    @PostMapping("/{id}/planning/generate-assignments")
    public ApiResponse<AssignmentPlanResponse> generateAssignments(@PathVariable UUID id) {
        return ApiResponse.ok(
                autoAssignmentService.generate(CurrentUser.require().getId(), id));
    }
}
