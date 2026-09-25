# common/exception

Typed exceptions and the global handler that converts them into the API envelope.

## What's in it

- `BaseException` — abstract `RuntimeException` carrying an HTTP `status` and a
  `code` string.
- `BadRequestException` (400), `UnauthorizedException` (401),
  `ForbiddenException` (403), `NotFoundException` (404, plus a
  `NotFoundException.of(entity, id)` helper), `ConflictException` (409) — thin
  subclasses of `BaseException` with a fixed status/code.
- `GlobalExceptionHandler` — `@RestControllerAdvice` mapping: any `BaseException`
  to its own status/code; `MethodArgumentNotValidException` to `400
  VALIDATION_FAILED` with per-field violations; Spring Security's
  `AccessDeniedException`/`AuthenticationException` to `403`/`401`;
  `IllegalArgumentException` to `400`; `ResponseStatusException` (used by
  `common/api/NotImplemented`) passed through with its own status/reason; any
  other `Exception` to `500 INTERNAL_ERROR` (logged).

## How it connects

Services and controllers throw these typed exceptions directly — controllers
never build an `ApiError`/`ApiResponse` by hand. `GlobalExceptionHandler` is the
single place that turns any exception into `ApiResponse.fail(ApiError...)` (see
`common/api/README.md`), so every error response in the app has the same shape
regardless of which layer threw.
