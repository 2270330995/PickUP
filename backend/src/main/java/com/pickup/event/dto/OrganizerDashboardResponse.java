package com.pickup.event.dto;

import java.util.List;

public record OrganizerDashboardResponse(
        int totalEvents,
        int activeEvents,
        List<EventDashboardSummary> events
) {}
