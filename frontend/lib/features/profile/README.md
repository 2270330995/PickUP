# features/profile

The organizer's own account screen: view/edit name and phone, jump to
vehicles or trips, sign out. Contains presentation only — data comes from
`features/user`.

## Subdirectories

- [`presentation/`](presentation/README.md) — `ProfileScreen`.

## How it connects

Routed at `/profile`. Builds on [`features/user`](../user/README.md) for
account data and `shared/providers/auth_provider.dart` for sign-out.
