# shared

Cross-feature state that doesn't belong to any single feature and that
`core/` (routing, networking) needs access to without depending on a
feature package.

## Subdirectories

- [`providers/`](providers/README.md) — `authProvider`/`AuthController`, the
  app's session state machine.

## How it connects

Sits between `core/` and `features/`: `core/router` and `core/network`
depend on `shared/providers/auth_provider.dart`, which in turn depends on
`features/auth/data` and `features/user/data`. See
[`../core/README.md`](../core/README.md) for how the router/network layer
consumes it.
