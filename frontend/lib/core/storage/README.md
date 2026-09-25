# core/storage

Persists the JWT access/refresh tokens issued by the backend's auth flow.

## Contents

- `secure_token_storage.dart` — `TokenStorage`, created via
  `TokenStorage.create()`, which picks a backend at runtime:
  - Mobile/web: `FlutterSecureStorage` (Keychain/Keystore-backed).
  - Desktop (macOS/Windows/Linux): `SharedPreferences`, so local dev doesn't
    require Keychain entitlements or code signing.
  - Exposes `readAccessToken()`, `readRefreshToken()`,
    `writeTokens({access, refresh})`, and `clear()`.
  - `secureTokenStorageProvider` — Riverpod `Provider<TokenStorage>` exposing
    the instance app-wide.

## How it connects

`core/network/api_client.dart` watches `secureTokenStorageProvider` to attach
`Authorization: Bearer <token>` headers to every outgoing request.
`shared/providers/auth_provider.dart`'s `AuthController` reads/writes tokens
here on login, register, and logout (including the 401-triggered logout
wired through `UnauthorizedNotifier` in `core/network`).
