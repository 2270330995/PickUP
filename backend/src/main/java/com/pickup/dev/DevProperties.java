package com.pickup.dev;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pickup.dev")
public record DevProperties(
        /** When true, exposes unauthenticated /api/v1/dev/* helpers. Never enable in production. */
        boolean enabled,
        /** Seed demo data automatically on startup when the database has no users. */
        boolean autoSeed,
        /** Password used for every demo account. */
        String password
) {
    public DevProperties {
        if (password == null || password.isBlank()) {
            password = "test";
        }
    }
}
