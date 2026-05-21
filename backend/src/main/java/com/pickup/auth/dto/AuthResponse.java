package com.pickup.auth.dto;

import com.pickup.user.dto.UserResponse;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        long expiresInSec,
        UserResponse user
) {}
