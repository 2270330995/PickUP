# Replace order-dependent greedy matching with a global distance sort

## Context

`DriverPassengerScorer.assign()` (`backend/src/main/java/com/pickup/event/planning/DriverPassengerScorer.java`)
currently assigns passengers to drivers by processing passengers one at a time,
in a fixed order (creation order in production), giving each one the closest
driver that still has a free seat. This is order-dependent: whichever
passenger is processed first for a contested driver "wins" that seat, even
when a later-processed passenger would benefit from it far more and the first
passenger would have been just as happy with a different driver.

This was validated with a concrete, geometrically-checked example: Driver A
and Driver B are 100 (units) apart. Passenger P1 sits at the 45% mark (closer
to A, but only mildly: 45 vs 55). Passenger P2 sits almost on top of A (1 vs
99). If P1 is processed first, it takes A's only seat — since A is *its*
closest driver — leaving P2 stuck riding the full 99 units with B, for a
total of 144. The better pairing (P1→B, P2→A) totals only 56.

Several fixes were discussed (a min-cost-flow solve, a swap-repair local
search pass). The user proposed a simpler alternative and tested it against
the validated example by hand: **compute the distance from every passenger to
every driver, sort all of those pairs ascending, and walk the sorted list
assigning each pair as long as the passenger isn't already assigned and the
driver still has a free seat.** Run against the example above, this correctly
produces the better pairing (P2→A first at cost 1, then P1→B at cost 55,
total 56) — it fixes the specific problem that motivated this work.

This is a known, accepted trade-off, not a proof of general optimality: a
second example was constructed and geometrically verified (real coordinates:
A=(0,0), B=(10,0), P1=(4,0), P2≈(3.05, 3.96), giving distances P1-A=4, P1-B=6,
P2-A=5, P2-B=8) where this algorithm still doesn't find the true optimum — it
greedily locks in the single globally-cheapest pair (P1-A=4) first, producing
a 12-cost result, when the true optimum (P1-B + P2-A = 6+5 = 11) is better.
The user explicitly chose to accept this — **ship the simpler global-sort
algorithm now, without a repair pass on top** — trading a theoretical
optimality guarantee for a much smaller, easier-to-understand change. To be
plain about it: this isn't just a contrived-test corner case — the same
"locks in the globally cheapest pair even when it blocks a better overall
outcome" failure mode can and will occur on real production event data
whenever the numbers happen to line up that way, not only in the specific
example constructed here. This should be captured as an explicit "known
limitation, accepted trade-off" test (see below) so a future contributor
doesn't mistake the remaining imperfect case for a bug.

## Design

All changes are contained to `DriverPassengerScorer.java`, its one test file,
and one small edit to its sole caller (`AutoAssignmentService.java`) to drop
an argument that's no longer needed. `StopOrderPlanner` and every other
downstream file are untouched.

**Signature change**: `assign(...)` currently takes a `destination: GeoPoint`
parameter, used only for the destination-alignment tie-break in the old
per-passenger comparator. The new algorithm has no equivalent secondary
signal — it's a pure distance sort, exactly as proposed — so `destination`
becomes dead weight. Drop it from both overloads:

```java
public static List<DriverAssignment> assign(
        List<EventParticipantEntity> drivers,
        List<EventParticipantEntity> passengers) {
    return assign(drivers, passengers, DistanceCalculator::distanceMeters);
}

public static List<DriverAssignment> assign(
        List<EventParticipantEntity> drivers,
        List<EventParticipantEntity> passengers,
        RouteDistanceMeter distanceMeter) {
    ...
}
```

`AutoAssignmentService.java:114-119` currently passes `destination` as the
3rd argument to `assign(...)`. Confirmed by reading the surrounding method
(`AutoAssignmentService.java:80-139`): the `destination` local variable
(line 112) is *also* used later at line 128 for
`StopOrderPlanner.orderPassengerIds(...)`, so this is a one-line edit —
remove just the `destination,` argument from the `assign(...)` call — not a
removal of the variable itself.

**New implementation of `assign(drivers, passengers, distanceMeter)`**:

```java
Map<UUID, Integer> remainingCapacity = new LinkedHashMap<>();
for (EventParticipantEntity driver : drivers) {
    VehicleEntity vehicle = driver.getVehicle();
    int maxPassengers = vehicle == null ? 0 : Math.max(0, vehicle.getSeats() - 1);
    remainingCapacity.put(driver.getId(), maxPassengers);
}

Map<UUID, List<UUID>> assignedByDriver = new LinkedHashMap<>();
for (EventParticipantEntity driver : drivers) {
    assignedByDriver.put(driver.getId(), new ArrayList<>());
}

List<CandidatePair> candidates = buildSortedCandidates(drivers, passengers, distanceMeter, remainingCapacity);

Set<UUID> assignedPassengerIds = new HashSet<>();
for (CandidatePair candidate : candidates) {
    UUID driverId = candidate.driver().getId();
    UUID passengerId = candidate.passenger().getId();
    if (assignedPassengerIds.contains(passengerId)) {
        continue; // already matched to a cheaper driver earlier in the sorted list
    }
    if (remainingCapacity.getOrDefault(driverId, 0) <= 0) {
        continue; // driver already full
    }
    assignedByDriver.get(driverId).add(passengerId);
    remainingCapacity.merge(driverId, -1, Integer::sum);
    assignedPassengerIds.add(passengerId);
}

// unchanged: build List<DriverAssignment> result from assignedByDriver, same as today
```

**New private helper `buildSortedCandidates(...)`** and record. Note this
stores the *entities* (`driver`/`passenger`), not just their ids — this is
what lets the tie-break be encoded directly in the sort comparator (see
"Determinism" below) rather than relying on stable-sort behavior plus
whatever order the pairs happened to be generated in:

```java
private record CandidatePair(double distanceMeters, EventParticipantEntity driver, EventParticipantEntity passenger) {}

private static List<CandidatePair> buildSortedCandidates(
        List<EventParticipantEntity> drivers,
        List<EventParticipantEntity> passengers,
        RouteDistanceMeter distanceMeter,
        Map<UUID, Integer> remainingCapacity) {

    List<CandidatePair> candidates = new ArrayList<>();
    for (EventParticipantEntity driver : drivers) {
        if (remainingCapacity.getOrDefault(driver.getId(), 0) <= 0) {
            continue; // no seats to offer at all (no vehicle, or seats <= 1)
        }
        Optional<GeoPoint> tripStart = GeoPoint.tripStartFromDriver(driver);
        if (tripStart.isEmpty()) {
            continue; // unknown location; can never be matched
        }
        for (EventParticipantEntity passenger : passengers) {
            GeoPoint pickup = GeoPoint.pickupFromPassenger(passenger).orElseThrow();
            double distance = distanceMeter.distanceMeters(tripStart.get(), pickup);
            candidates.add(new CandidatePair(distance, driver, passenger));
        }
    }

    candidates.sort(
            Comparator.comparingDouble(CandidatePair::distanceMeters)
                    .thenComparing(CandidatePair::driver, participantOrder())
                    .thenComparing(CandidatePair::passenger, participantOrder()));
    return candidates;
}
```

Notes on this design:
- **Determinism**: the comparator itself encodes the tie-break —
  `.thenComparing(CandidatePair::driver, participantOrder())` then the same
  for `passenger` — using the existing `participantOrder()` comparator
  (`createdAt` then `id`) already defined in this class. This is deliberately
  *not* left to fall out of "generation order + stable sort": an earlier
  draft of this plan relied on that implicit invariant (pre-sorting
  `drivers`/`passengers` before the nested loop, then trusting `List.sort`'s
  stability to preserve it), which would have silently broken under an
  innocuous future refactor — e.g. someone rewrites the nested loop as a
  `flatMap`, or reorders which list is outer vs. inner, and the tie-break
  changes with no compiler warning and no obvious diff signal. Encoding it
  directly in the comparator makes it self-documenting and refactor-safe.
  This tie-break rule is also a **behavior change** from today's (which
  preferred the driver with more remaining capacity on a proximity tie) —
  covered by test 3 below, plus a new test 8 for the symmetric passenger-side
  tie (two passengers competing for one driver's last seat), since the
  comparator's two `.thenComparing(...)` clauses are independent claims that
  each need their own test.
- **Drivers with no vehicle or ≤1 seat** are filtered out before any distance
  calculation, via the already-computed `remainingCapacity` map (no duplicate
  capacity-math needed).
- **Drivers with an unknown trip start** (`GeoPoint.tripStartFromDriver`
  returns empty) never generate any candidate pairs, so they can never
  receive a passenger. This is a **behavior change**: today, such a driver
  could still receive an overflow passenger as a last resort (via the old
  `bestDriver == null` fallback, since *some* driver had to be picked). Under
  the new algorithm, a passenger who could only ever go to a
  location-unknown driver is left **unassigned** instead. This edge case
  isn't exercised by any test today (grepped: no existing test calls
  `PlanningTestSupport.driverWithoutTripStart`), so it isn't breaking a
  documented contract — and it isn't a silent regression either: confirmed by
  reading `AssignmentService.buildPlanResponse()`
  (`backend/src/main/java/com/pickup/event/assignment/AssignmentService.java:266-281`)
  that "unassigned" is computed generically as *any assignable-status
  passenger not on any trip's stop list*, with no distinction by cause. A
  passenger stuck unassigned because their only viable driver has an unknown
  location will surface through the exact same `unassignedConfirmedPassengerIds`
  count and organizer-facing "N unassigned" snackbar message
  (`autoAssignSummaryMessage`, shown at `event_detail_screen.dart:999`) that
  today's capacity-overflow case already produces — no new UI work needed,
  but still worth a dedicated test (below) since it's new *emergent*
  behavior of this method, even though nothing downstream needs to change.
- Passengers are still assumed to always have a valid pickup point
  (`.orElseThrow()`), matching the existing contract — `AutoAssignmentService`
  only ever passes passengers with a complete pickup location.
- Methods removed entirely (no longer referenced by anything):
  `compareDrivers`, `proximityMeters`, `destinationAlignmentMeters`. Kept:
  `participantOrder()`. New imports needed: `java.util.Optional`,
  `java.util.HashSet`, `java.util.Set` (plus the already-imported
  `Comparator`, now also used for `Comparator.comparingDouble`).

## Tests

All in `backend/src/test/java/com/pickup/event/planning/DriverPassengerScorerTest.java`,
same style as today (plain JUnit 5, real lat/lng coordinates through the real
`DistanceCalculator`, no mocking framework). **No changes needed to
`PlanningTestSupport.java`** — `driverWithoutTripStart` already exists there
for the one test that needs it. Every `assign(...)` call in the test file
drops the now-removed `destination` argument (and the unused `DESTINATION`
constant can be deleted).

1. **`assignsPassengerToCloserDriverByTripStart`** — existing test, unchanged
   assertions. Traced by hand: with only one passenger, "closest driver
   wins" behaves identically under the new algorithm.
2. **`eachPassengerAssignedAtMostOnce_overflowStaysUnassigned`** — existing
   test, unchanged assertions. Traced by hand: single driver, capacity 1, two
   passengers at different distances — the new algorithm still assigns the
   closer one and leaves the other unassigned, same as today.
3. **`equidistantDrivers_tieBrokenByCreationOrder`** (renamed and
   re-asserted from `equidistantDrivers_prefersMoreRemainingCapacity`) — two
   drivers at the same location (so their distance to the one passenger
   ties exactly), different `createdAt` and different seat counts. **New
   assertion**: the driver with the *earlier* `createdAt` wins the tie now
   (not the one with more capacity) — this documents the intentional
   tie-break behavior change called out in the design section.
4. **`globalSortFixesOrderDependentMisassignment`** (new — the core
   motivating case) — recreates the validated A/B/P1/P2 example (A and B 100
   apart, P1 at the 45% mark, P2 almost on top of A, both drivers capacity
   1). Asserts the result is the optimal pairing: A→[P2], B→[P1].
5. **`knownLimitation_globalSortCanMissTrueOptimum`** (new — documents the
   accepted trade-off) — a scenario built from the geometrically-verified
   4/5/6/8 counterexample (driver pair further apart than the passengers'
   spread, so the single globally-cheapest pair "greedily wins" and blocks
   the true optimum). Exact coordinates will be tuned during implementation
   and confirmed by actually running the test (the hand-verified flat-plane
   construction needs re-checking against the real Haversine-based
   `DistanceCalculator` at whatever scale is used) — the requirement is that
   the qualitative relationship (locking in the single cheapest pair first
   gives a strictly worse total than the alternative pairing) holds. Include
   a comment explaining this is intentionally-accepted, not a bug.
6. **`driverWithoutVehicle_neverReceivesAssignment`** (new) — a driver with
   `vehicle = null` positioned exactly on top of a passenger (distance 0),
   alongside a second driver further away but with capacity. Asserts the
   passenger goes to the farther driver, confirming zero-capacity drivers are
   excluded regardless of proximity.
7. **`driverWithoutTripStart_leavesPassengerUnassigned`** (new) — using
   `PlanningTestSupport.driverWithoutTripStart(...)` as the *only* driver
   with capacity, one passenger. Asserts the result is empty (passenger stays
   unassigned) — documents the behavior change called out in the design
   section, replacing the old fallback-assignment behavior that no test
   currently locks in.
8. **`equidistantPassengers_tieBrokenByCreationOrder`** (new) — the symmetric
   counterpart to test 3. One driver, capacity 1, two passengers at the exact
   same distance from it (e.g. identical pickup coordinates), different
   `createdAt`. Asserts the earlier-created passenger gets the seat. Test 3
   only proves the comparator's driver-side tie-break
   (`.thenComparing(CandidatePair::driver, participantOrder())`); this proves
   the independent passenger-side clause
   (`.thenComparing(CandidatePair::passenger, participantOrder())`) — without
   it, only half of the explicit tie-break design would actually be covered.

## Verification

1. `cd backend && ./mvnw test -Dtest=DriverPassengerScorerTest` — all 8 tests
   (2 unchanged, 1 re-asserted, 5 new) pass. **In particular, test 5
   (`knownLimitation_globalSortCanMissTrueOptimum`) is not considered done
   just because its coordinates were checked by hand on a flat plane** — the
   design section's numbers were verified against straight-line Euclidean
   distance, not the real Haversine-based `DistanceCalculator` this test
   actually runs through. Run it, confirm it fails/passes as expected, and
   adjust the coordinates if the real distance calculation doesn't reproduce
   the intended 12-vs-11 relationship, before treating this test as locked
   in.
2. `cd backend && ./mvnw test` — full backend suite, to confirm the signature
   change to `assign(...)` doesn't break anything beyond the one call site
   already identified (grepped: `DriverPassengerScorer.assign` has exactly
   one production caller and one test file referencing it — no other file
   needs to change).
3. Rebuild and restart the backend container to pick up the change:
   `docker compose up --build -d backend` (no database migration involved —
   this is a pure code change).
4. Optional doc touch-up: `backend/src/test/java/com/pickup/event/planning/README.md`
   and `backend/src/test/java/com/pickup/event/README.md` currently describe
   `DriverPassengerScorerTest` in terms of the old "closer driver by
   proximity" algorithm — worth a short rewrite to describe the global-sort
   approach instead, so the README stays accurate.
