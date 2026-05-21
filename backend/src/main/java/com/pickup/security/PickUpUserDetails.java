package com.pickup.security;

import com.pickup.common.enums.SystemRole;
import com.pickup.user.UserEntity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Spring Security principal backed by a {@link UserEntity}. Exposes {@link #getId()}
 * so controllers can pull the current user's id via {@code @AuthenticationPrincipal}.
 */
public class PickUpUserDetails implements UserDetails {

    private final UUID id;
    private final String email;
    private final String passwordHash;
    private final Set<SystemRole> systemRoles;

    public PickUpUserDetails(UserEntity user) {
        this.id = user.getId();
        this.email = user.getEmail();
        this.passwordHash = user.getPasswordHash();
        this.systemRoles = Set.copyOf(user.getSystemRoles());
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public Set<SystemRole> getSystemRoles() {
        return systemRoles;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return systemRoles.stream()
                .map(r -> new SimpleGrantedAuthority("ROLE_" + r.name()))
                .collect(Collectors.toUnmodifiableSet());
    }

    @Override
    public String getPassword() {
        return passwordHash;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
