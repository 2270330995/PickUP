package com.pickup.security;

import com.pickup.common.exception.UnauthorizedException;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    public static final String TYPE_ACCESS = "access";
    public static final String TYPE_REFRESH = "refresh";
    private static final String CLAIM_TYPE = "typ";

    private final JwtProperties properties;
    private final SecretKey signingKey;

    public JwtTokenProvider(JwtProperties properties) {
        this.properties = properties;
        byte[] keyBytes = properties.secret().getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            throw new IllegalStateException(
                    "pickup.security.jwt.secret must be at least 32 bytes for HS256");
        }
        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public String createAccessToken(UUID userId) {
        return buildToken(userId, TYPE_ACCESS, properties.accessTokenTtlMs());
    }

    public String createRefreshToken(UUID userId) {
        return buildToken(userId, TYPE_REFRESH, properties.refreshTokenTtlMs());
    }

    public long accessTokenTtlSeconds() {
        return properties.accessTokenTtlMs() / 1000;
    }

    /**
     * Parses the token, verifies signature + expiry, and asserts the expected {@code typ} claim.
     * Returns the user id (sub claim).
     */
    public UUID parseAndRequireType(String token, String expectedType) {
        try {
            Jws<Claims> jws = Jwts.parser()
                    .verifyWith(signingKey)
                    .requireIssuer(properties.issuer())
                    .build()
                    .parseSignedClaims(token);
            Claims claims = jws.getPayload();
            String typ = claims.get(CLAIM_TYPE, String.class);
            if (!expectedType.equals(typ)) {
                throw new UnauthorizedException("Token is not a " + expectedType + " token");
            }
            return UUID.fromString(claims.getSubject());
        } catch (JwtException | IllegalArgumentException e) {
            throw new UnauthorizedException("Invalid or expired token");
        }
    }

    private String buildToken(UUID userId, String type, long ttlMs) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim(CLAIM_TYPE, type)
                .issuer(properties.issuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(ttlMs)))
                .signWith(signingKey, Jwts.SIG.HS256)
                .compact();
    }
}
