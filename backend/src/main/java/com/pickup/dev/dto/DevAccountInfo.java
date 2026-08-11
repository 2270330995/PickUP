package com.pickup.dev.dto;

public record DevAccountInfo(
        String email,
        String fullName,
        String role,
        String password
) {}
