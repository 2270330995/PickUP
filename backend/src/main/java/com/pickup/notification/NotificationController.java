package com.pickup.notification;

import com.pickup.common.api.ApiResponse;
import com.pickup.common.api.NotImplemented;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    @GetMapping
    public ApiResponse<Void> list() {
        return NotImplemented.phase1("GET /api/v1/notifications");
    }

    @PostMapping("/{id}/read")
    public ApiResponse<Void> markRead(@PathVariable UUID id) {
        return NotImplemented.phase1("POST /api/v1/notifications/{id}/read");
    }
}
