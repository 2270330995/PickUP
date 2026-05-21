package com.pickup.auth;

import com.pickup.auth.dto.AuthResponse;
import com.pickup.auth.dto.LoginRequest;
import com.pickup.auth.dto.RefreshRequest;
import com.pickup.auth.dto.RegisterRequest;
import com.pickup.common.enums.SystemRole;
import com.pickup.common.exception.ConflictException;
import com.pickup.common.exception.UnauthorizedException;
import com.pickup.security.JwtTokenProvider;
import com.pickup.user.UserEntity;
import com.pickup.user.UserMapper;
import com.pickup.user.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    public AuthService(UserRepository userRepository,
                       UserMapper userMapper,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ConflictException("Email is already registered");
        }
        UserEntity user = UserEntity.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(request.password()))
                .fullName(request.fullName().trim())
                .phone(request.phone() == null || request.phone().isBlank() ? null : request.phone().trim())
                .systemRoles(EnumSet.of(SystemRole.USER))
                .build();
        user = userRepository.save(user);
        return buildTokens(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();
        UserEntity user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new UnauthorizedException("Invalid email or password"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid email or password");
        }
        return buildTokens(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse refresh(RefreshRequest request) {
        UUID userId = tokenProvider.parseAndRequireType(request.refreshToken(), JwtTokenProvider.TYPE_REFRESH);
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new UnauthorizedException("User no longer exists"));
        return buildTokens(user);
    }

    private AuthResponse buildTokens(UserEntity user) {
        String access = tokenProvider.createAccessToken(user.getId());
        String refresh = tokenProvider.createRefreshToken(user.getId());
        return new AuthResponse(
                access,
                refresh,
                tokenProvider.accessTokenTtlSeconds(),
                userMapper.toResponse(user)
        );
    }
}
