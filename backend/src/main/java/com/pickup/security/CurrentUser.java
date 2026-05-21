package com.pickup.security;

import com.pickup.common.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Convenience accessor for the authenticated principal.
 */
public final class CurrentUser {

    private CurrentUser() {}

    public static PickUpUserDetails require() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || !(auth.getPrincipal() instanceof PickUpUserDetails details)) {
            throw new UnauthorizedException("Authentication required");
        }
        return details;
    }
}
