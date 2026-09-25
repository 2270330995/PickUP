# security

Stateless JWT authentication plumbing: token issuance/parsing, the request
filter, the Spring Security principal, and a convenience accessor for
controllers.

## What's in it

- `JwtTokenProvider` — HS256 signing (key derived from
  `pickup.security.jwt.secret`, must be >= 32 bytes or the bean fails to
  construct). `createAccessToken`/`createRefreshToken` embed a `typ` claim
  (`access`/`refresh`) and the user id as `sub`. `parseAndRequireType` verifies
  signature, issuer, and expected `typ`, throwing `UnauthorizedException` on any
  failure (invalid signature, wrong type, expired).
- `JwtProperties` — `@ConfigurationProperties(prefix =
  "pickup.security.jwt")`: `secret`, `accessTokenTtlMs`, `refreshTokenTtlMs`,
  `issuer`.
- `JwtAuthenticationFilter` — `OncePerRequestFilter`: extracts a `Bearer` token,
  parses/validates it as an access token, loads the user via
  `CustomUserDetailsService.loadById`, and populates the
  `SecurityContextHolder`. Invalid/missing tokens simply leave the context
  unauthenticated (no exception thrown here) — `SecurityConfig` converts that
  into a 401 downstream via `JwtAuthenticationEntryPoint`.
- `JwtAuthenticationEntryPoint` — writes a `401` `ApiResponse.fail(...)` JSON
  body directly (this is the one place outside `GlobalExceptionHandler` that
  builds the envelope by hand, since Spring Security's entry point runs outside
  the normal exception-handler chain).
- `CustomUserDetailsService` — `UserDetailsService` (by email) plus a
  `loadById(UUID)` used by the filter.
- `PickUpUserDetails` — `UserDetails` wrapping a `UserEntity`; exposes `getId()`
  and maps `SystemRole` to `ROLE_*` `GrantedAuthority`s.
- `CurrentUser` — static `require()` accessor: pulls the authenticated
  `PickUpUserDetails` from `SecurityContextHolder`, throwing
  `UnauthorizedException` if absent. Used by nearly every controller instead of
  `@AuthenticationPrincipal`.
- `PasswordConfig` — `BCryptPasswordEncoder` bean.

## How it connects

- Wired together by `config/SecurityConfig`, which installs
  `JwtAuthenticationFilter` ahead of Spring's username/password filter and
  registers `JwtAuthenticationEntryPoint` for auth failures.
- `auth/AuthService` is the only place that calls `JwtTokenProvider.create*`;
  every other controller calls `CurrentUser.require()` to get the caller's id.
- Depends on `user/UserRepository`/`UserEntity` and
  `common/exception.UnauthorizedException`.
