# core/theme

App-wide Material 3 theme definition.

## Contents

- `app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` build a
  `ThemeData` from a single seed color (`Color(0xFF1E88E5)`) via
  `ColorScheme.fromSeed`, plus small overrides: flat, centered `AppBar`,
  surface-colored scaffold background, and a `FilledButton` style with a
  48px minimum height and 12px rounded corners. Marked as a "Phase 1" theme —
  intentionally minimal, not a final design system.

## How it connects

`lib/app.dart` calls `AppTheme.light()`/`AppTheme.dark()` when constructing
the root `MaterialApp.router`, driven by the device's `ThemeMode.system`. No
providers, no dependencies on other `core/` or `features/` code.
