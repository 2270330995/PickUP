package com.pickup.notification.dto;

import com.pickup.common.enums.NotificationType;

import java.time.Instant;
import java.util.UUID;

/**
 * Phase 1 placeholder. Populated in Phase 2 when notifications are wired.
 */
public record NotificationResponse(
        UUID id,
        NotificationType type,
        String title,
        String body,
        boolean read,
        Instant createdAt
) {}
