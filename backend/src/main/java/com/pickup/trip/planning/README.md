# trip/planning

Post-assignment route enrichment: stamps static planning ETAs onto a
newly-created trip's stops.

## What's in it

- `TripRouteEnrichmentService.enrichTrip(trip, event)` — walks the trip's stops
  in sequence order, accumulating `RouteEstimateService.estimateOrFallback`
  duration leg-by-leg from a resolved route origin (the driver's trip-start via
  `GeoPoint.tripStartFromDriver`, falling back to the first stop's coordinates if
  no trip-start is set), and sets each stop's `etaMinutes` to the cumulative
  duration rounded up to a whole minute (`toEtaMinutes`, package-visible for
  testing). Also attempts `RouteEstimateService.fetchRoutePolyline` for the full
  waypoint chain (stops + destination) — currently always empty since polyline
  parsing isn't implemented yet.

## How it connects

Called once per trip by `event/assignment/AssignmentService.submit` right after
building each `TripEntity`, before saving. Depends on
`common/geo/routing/RouteEstimateService` (never a provider directly),
`common.geo.GeoPoint`, and `participant/EventParticipantRepository` (to resolve
a legacy user-backed driver's trip-start when the trip has no
`driverParticipant` link).
