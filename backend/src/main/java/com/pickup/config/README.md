# config

Spring `@Configuration` classes wiring security and WebSocket infrastructure.

## What's in it

- `SecurityConfig` — the `SecurityFilterChain`: disables CSRF (stateless JWT API),
  configures CORS (`allowedOriginPatterns: *`, credentials allowed), sets
  `SessionCreationPolicy.STATELESS`, registers `JwtAuthenticationEntryPoint` for
  auth failures, permits `/api/v1/auth/**`, `/ws/**`, `/actuator/health`,
  `/error` unauthenticated, and additionally permits `/api/v1/dev/**` only when
  `DevProperties.enabled()` is true; everything else requires authentication.
  Installs `security/JwtAuthenticationFilter` before
  `UsernamePasswordAuthenticationFilter`. Also exposes the `AuthenticationManager`
  bean.
- `WebSocketConfig` — registers the `/ws` STOMP endpoint (SockJS, any origin) and
  enables a simple broker on `/topic`/`/queue` with `/app` as the application
  prefix. No `@MessageMapping` handlers exist yet — this is wiring only.

## How it connects

`SecurityConfig` is the single source of truth for which paths are public; it
reads `DevProperties` (`dev/`) to conditionally open the dev-seed endpoints and
depends on `security/` for the filter, entry point, and JWT properties it wires
together. `WebSocketConfig` has no consumers yet elsewhere in the codebase — it's
infrastructure for a future real-time feature (e.g. live trip updates).
