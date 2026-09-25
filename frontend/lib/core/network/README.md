# core/network

The app's single HTTP client setup: base `dio` configuration, the backend's
`ApiResponse<T>` envelope model, and a normalized exception type for call
sites to catch.

## Contents

- `api_client.dart`
  - `dioProvider` — builds the shared `Dio` instance: base URL
    `$PICKUP_API_BASE_URL/api/v1` (default `http://localhost:8080`, override
    via `--dart-define=PICKUP_API_BASE_URL=...`), 10s connect / 15s receive
    timeouts, JSON headers.
  - Request interceptor reads the access token from
    `secureTokenStorageProvider` (`core/storage`) and attaches
    `Authorization: Bearer <token>`.
  - Error interceptor: on a 401 from any non-`/auth/**` path, calls
    `unauthorizedNotifierProvider.trigger()`; auth endpoints are left to
    surface 401 as an ordinary `ApiException` (e.g. bad login credentials)
    without forcing a session reset.
  - `UnauthorizedNotifier`/`unauthorizedNotifierProvider` — a settable
    callback hook. `shared/providers/auth_provider.dart`'s `AuthController`
    subscribes to it to clear stored tokens and redirect to `/login`. Feature
    API clients should never do their own 401 handling.
  - `ApiClient`/`apiClientProvider` — thin wrapper exposing the configured
    `Dio` as `.raw`; feature `data/` API classes take an `ApiClient` (or its
    `Dio`) in their constructor.
- `api_response.dart` — `ApiResponse<T>`, `ApiError`, `FieldViolation`: mirror
  the backend's `common/api/ApiResponse.java` envelope
  (`{success, data, error}`) and its `ApiError` shape
  (`code`, `message`, `fieldErrors`) produced by `GlobalExceptionHandler`.
- `api_exception.dart` — `ApiException`: the normalized error every API call
  site throws/catches. `ApiException.fromDio(DioException)` unwraps a Dio
  failure's response body into `ApiResponse.error` when present, otherwise
  maps the `DioExceptionType` (timeout, connection error, cancel) to a
  synthetic code. Convenience getters: `isUnauthorized`, `isForbidden`,
  `isConflict`, `isNotFound`.

## How it connects

Every `features/*/data/*_api.dart` client is built on `dioProvider`/
`apiClientProvider` and converts Dio failures via
`ApiException.fromDio`. Depends on `core/storage` (token read) and is
depended on by `shared/providers/auth_provider.dart` (unauthorized handling)
and all feature data layers.
