# event/planning (tests)

Unit tests for the proximity-scoring and stop-ordering heuristics, using plain
`GeoPoint` math (no mocked routing provider — both classes accept a
`RouteDistanceMeter` and these tests exercise the default Haversine overload).

## What's tested

- `DriverPassengerScorerTest` — every (driver, passenger) pair is scored by
  trip-start distance and consumed globally cheapest-first (not per-passenger),
  so a passenger goes to the closer driver even when a different passenger is
  processed "first"; ties are broken deterministically by driver/passenger
  creation order (encoded directly in the sort comparator); a driver at
  capacity leaves excess passengers unassigned rather than over-filling; a
  driver with no vehicle or unknown trip-start location can never receive a
  passenger. One test (`knownLimitation_globalSortCanMissTrueOptimum`)
  documents an accepted trade-off: this is a greedy heuristic, not a
  min-cost-matching solve, so it can still produce a worse total distance than
  the true optimum in some cases — see `driver-passenger-matching-plan.md` at
  the repo root for the full discussion.
- `StopOrderPlannerTest` — nearest-neighbor ordering from a driver's trip start;
  reverse nearest-neighbor ordering (far-to-near) when the driver has no trip
  start, walking backward from the destination; a single stop is returned
  unchanged.
- `PlanningTestSupport` — shared test fixture: builds `EventParticipantEntity`
  drivers (with/without a trip-start location) and passengers with a given
  `createdAt` (set via reflection, since `BaseEntity.createdAt` has no public
  setter) so ordering tie-breaks are deterministic across tests.
