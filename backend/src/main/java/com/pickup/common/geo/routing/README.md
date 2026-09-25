# common/geo/routing

Pluggable travel-time/distance estimation, with a real-routing provider and a
deterministic fallback. This is the layer the auto-assignment pipeline (see
`event/planning/README.md`) and trip enrichment (`trip/planning/README.md`) go
through for every distance/duration number — neither calls a provider directly.

## What's in it

- `RouteEstimateProvider` — interface: `Optional<TravelMetrics>
  estimate(GeoPoint origin, GeoPoint destination)`.
- `HaversineTravelProvider` — always-available fallback: great-circle distance
  from `common.geo.DistanceCalculator` divided by an assumed urban driving speed
  (`TravelProperties.assumedSpeedMps`, default 11 m/s) to derive a duration.
  Never returns empty.
- `GoogleRoutesTravelProvider` — calls Google's Routes API
  (`computeRoutes`, traffic-unaware) when `pickup.google.routes.enabled=true`
  (`@ConditionalOnProperty`) and an API key is configured; returns empty on any
  HTTP/parse failure so the caller can fall back. `parseDurationSeconds` parses
  the API's `"123s"`-style proto duration string.
- `RouteEstimateService` — the entry point everything else calls:
  `estimateOrFallback` tries the optional Google provider first, falls back to
  Haversine (which never throws); `distanceMeters` is a convenience wrapper;
  `fetchRoutePolyline` is a stub that always returns empty (no polyline parser
  yet).
- `RouteDistanceMeter` — `@FunctionalInterface` (`distanceMeters(from, to)`) used
  to inject a distance function into `DriverPassengerScorer` /
  `StopOrderPlanner` without depending on the full estimate pipeline.
- `TravelMetrics` — record: `distanceMeters`, `durationSeconds`, `source`.
- `TravelEstimateSource` — `HAVERSINE` or `GOOGLE_ROUTES`.
- `GoogleRoutesProperties` / `TravelProperties` — `@ConfigurationProperties` for
  `pickup.google.routes.*` and `pickup.google.travel.*`.

## How it connects

`RouteEstimateService` is injected into `event/planning/AutoAssignmentService`
(via `routeEstimateService::distanceMeters` passed as a `RouteDistanceMeter` into
`DriverPassengerScorer`/`StopOrderPlanner`) and into
`trip/planning/TripRouteEnrichmentService` (for per-stop ETA minutes). Depends on
`common/geo` for `GeoPoint`/`DistanceCalculator`.
