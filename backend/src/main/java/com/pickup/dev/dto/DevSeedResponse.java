package com.pickup.dev.dto;

import java.util.List;
import java.util.UUID;

public record DevSeedResponse(
        UUID eventId,
        String eventTitle,
        boolean alreadyExisted,
        List<DevAccountInfo> accounts
) {}
