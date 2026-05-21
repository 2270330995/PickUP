package com.pickup.event;

import com.pickup.common.api.ApiResponse;
import com.pickup.event.dto.OrganizerDashboardResponse;
import com.pickup.security.CurrentUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/organizer")
public class OrganizerDashboardController {

    private final EventService eventService;

    public OrganizerDashboardController(EventService eventService) {
        this.eventService = eventService;
    }

    @GetMapping("/dashboard")
    public ApiResponse<OrganizerDashboardResponse> dashboard() {
        return ApiResponse.ok(eventService.getOrganizerDashboard(CurrentUser.require().getId()));
    }
}
