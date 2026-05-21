package com.pickup.user.dto;

import com.pickup.common.enums.SystemRole;

import java.time.Instant;
import java.util.Set;
import java.util.UUID;

/**
 * Public projection of {@code UserEntity}. Never expose the entity directly —
 * map to this record via {@code UserMapper}.
 */
public record UserResponse(
        UUID id,
        String email,
        String fullName,
        String phone,
        Set<SystemRole> systemRoles,
        Instant createdAt
) {}
