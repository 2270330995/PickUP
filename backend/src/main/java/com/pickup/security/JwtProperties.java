package com.pickup.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pickup.security.jwt")
public record JwtProperties(
        String secret,
        long accessTokenTtlMs,
        long refreshTokenTtlMs,
        String issuer
) {
}
