# common/geo/routing (tests)

Unit tests for the travel-estimate providers and the service that picks between
them.

## What's tested

- `HaversineTravelProviderTest` — same-point distance is ~0 with a floored
  1-second duration; a known short distance scales with the configured assumed
  speed.
- `GoogleRoutesTravelProviderTest` — `parseDurationSeconds` parses the API's
  `"123s"`-style proto duration string, including a sub-second value rounding up
  to 1, and an empty string yielding `0`.
- `RouteEstimateServiceTest` — falls back to Haversine when no Google provider is
  present, prefers a Google estimate when the (stubbed) provider returns one, and
  falls back to Haversine when the Google provider returns empty. Uses a
  `RouteEstimateProvider` lambda stub rather than mocking `GoogleRoutesTravelProvider`
  directly, exercising the package-visible test constructor of
  `RouteEstimateService`.

No custom fixtures beyond building `TravelProperties`/`GeoPoint` inline.
