# test

Frontend test suite, mirroring `lib/` (per the repo's `CLAUDE.md` testing
convention).

## Current state

There is currently only one test file here: `widget_test.dart`. It is the
**stock Flutter counter-app test** left over from `flutter create` and does
not exercise this app at all — it calls `tester.pumpWidget(const MyApp())`
and asserts on a `0`/`1` counter and a `+` icon, none of which exist in this
codebase. In fact `MyApp` isn't even defined anywhere in `lib/` (the real
root widget is `PickUpApp` in `lib/app.dart`), so this file is dead
boilerplate rather than a passing smoke test for the real app.

There is no other test coverage under `frontend/` at this time, despite the
repo's CLAUDE.md and standing project convention that every new
feature/widget/provider should ship with unit tests under
`test/...` mirroring `lib/...`.

## What real coverage should look like

New tests should go under paths mirroring `lib/`, e.g.:

- `test/core/network/api_exception_test.dart` for `lib/core/network/api_exception.dart`
- `test/features/auth/data/auth_api_test.dart` for `lib/features/auth/data/auth_api.dart`
- `test/features/trip/presentation/trip_detail_screen_test.dart` for the
  trip detail widget

Run the suite with `flutter test` (from `frontend/`), or a single file with
`flutter test test/path/to/some_test.dart`.
