package com.pickup.user.dto;

import jakarta.validation.constraints.Size;

/**
 * Phase 2: only fullName and phone are mutable. Email and password are immutable for now;
 * a password-change flow lands in a later phase.
 */
public record UpdateUserRequest(
        @Size(min = 1, max = 120) String fullName,
        @Size(max = 32) String phone
) {}
