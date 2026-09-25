# event/planning (tests)

Unit tests for the proximity-scoring and stop-ordering heuristics, using plain
`GeoPoint` math (no mocked routing provider — both classes accept a
`RouteDistanceMeter` and these tests exercise the default Haversine overload).

## What's tested

- `DriverPassengerScorerTest` — a passenger is assigned to the closer driver by
  trip-start distance; equidistant drivers are broken by remaining seat capacity
  (prefers more room); a driver at capacity leaves excess passengers unassigned
  rather than over-filling.
- `StopOrderPlannerTest` — nearest-neighbor ordering from a driver's trip start;
  reverse nearest-neighbor ordering (far-to-near) when the driver has no trip
  start, walking backward from the destination; a single stop is returned
  unchanged.
- `PlanningTestSupport` — shared test fixture: builds `EventParticipantEntity`
  drivers (with/without a trip-start location) and passengers with a given
  `createdAt` (set via reflection, since `BaseEntity.createdAt` has no public
  setter) so ordering tie-breaks are deterministic across tests.
