package com.pickup.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @Email @NotBlank String email,
        @NotBlank @Size(max = 100) String password,
        @NotBlank @Size(max = 120) String fullName,
        @Size(max = 32) String phone
) {}
