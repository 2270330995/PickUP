# core/format

Small, dependency-free formatting helpers shared across features.

## Contents

- `eta_format.dart` — formats ETA (estimated time of arrival) minutes for
  display in trip/stop UIs:
  - `formatEtaMinutes(int? etaMinutes, {prefix = '~'})` → `"~12 min from
    start"`, or `null` if the value is missing/non-positive.
  - `formatEtaMinutesShort(int? etaMinutes)` → `"~12 min"`.
  - `maxEtaMinutes(Iterable<int?> values)` — returns the largest non-null
    value in a list, used to summarize a trip's overall ETA from its stops'
    individual ETAs.

## How it connects

Pure functions with no Riverpod/Flutter dependencies (aside from returning
`String?`/`int?`). Consumed by trip and stop presentation widgets (e.g.
`features/trip/presentation`) that render route-estimate data coming from the
backend's `RouteEstimateService` via `trip`/`assignment` DTOs.
