# common/api

The API envelope every controller in the app returns.

## What's in it

- `ApiResponse<T>` — record wrapping every response: `success`, `data`, `error`
  (`ApiError`, null on success), `timestamp`. Static factories `ok(data)`, `ok()`,
  `fail(error)`.
- `ApiError` — `code`, `message`, optional `fieldErrors` (list of
  `FieldViolation`), optional `details` map. `@JsonInclude(NON_NULL)` keeps
  successful responses free of null noise.
- `PageResponse<T>` — flattens a Spring Data `Page<T>` into `items`, `page`,
  `size`, `totalElements`, `totalPages`, `hasNext`.
- `NotImplemented` — throws a `501` `ResponseStatusException` for endpoints
  declared but not yet built; used by placeholder controllers (e.g.
  `notification/NotificationController`, some of `user/UserController`).

## How it connects

Every `@RestController` in the codebase returns `ApiResponse<T>` from
`ApiResponse.ok(...)`. `common/exception/GlobalExceptionHandler` is the only place
that calls `ApiResponse.fail(...)`, converting thrown exceptions into this same
envelope so success and error responses share one shape. `PageResponse` is
available for paginated endpoints but not yet used anywhere in this codebase.
