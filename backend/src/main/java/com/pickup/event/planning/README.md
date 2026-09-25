# event/planning

The auto-assignment pipeline: turns an event's eligible drivers/passengers into a
scored, ordered plan and hands it to `event/assignment/AssignmentService` for
persistence. This is the pipeline the root `CLAUDE.md` describes under
"Auto-assignment pipeline" — read this file alongside
`common/geo/routing/README.md` before changing anything distance-related, since
neither class here calls a `RouteEstimateProvider` directly.

## What's in it

- `AutoAssignmentService.generate(organizerId, eventId)` — orchestrates the whole
  flow:
  1. Sets `EventPlanningStatus.IN_PROGRESS` and saves.
  2. Loads all participants and existing trips; computes locked driver/passenger
     IDs via `event.assignment.AssignmentPreservation` (in-flight trips are never
     reshuffled).
  3. Filters eligible drivers (role `DRIVER`, assignable status, has a vehicle,
     not locked) and eligible passengers (role `PASSENGER`, assignable status,
     complete pickup location, not locked), both sorted deterministically by
     `(createdAt, id)`.
  4. Runs `DriverPassengerScorer.assign(...)` to match passengers to drivers.
  5. For each driver's passenger list, runs `StopOrderPlanner.orderPassengerIds`
     to sequence stops.
  6. Builds a `SubmitAssignmentsRequest` and delegates to
     `AssignmentService.submit` for persistence.
  7. On success: `EventPlanningStatus.READY` + `assignmentGenerated = true`. On
     any `RuntimeException`: delegates to `EventPlanningStatusWriter.markFailed`
     (a separate `REQUIRES_NEW` transaction) before rethrowing, so a `FAILED`
     marker survives rollback of the main transaction.
- `DriverPassengerScorer` — greedy proximity matching. For each passenger (in
  order), picks the best driver with remaining seat capacity by comparing (in
  order): distance from the driver's trip-start (`GeoPoint.tripStartFromDriver`)
  to the passenger's pickup; remaining capacity (prefers more room); alignment
  with the destination heading; then a deterministic `(createdAt, id)`
  tie-break. Drivers with no trip-start location always sort last
  (`Double.MAX_VALUE`).
- `StopOrderPlanner` — deterministic intra-trip stop ordering after passengers
  are assigned to a driver: nearest-neighbor walk from the driver's trip start
  when one is set, otherwise a reverse nearest-neighbor walk backward from the
  event destination (so the last stop ends up closest to the destination).
- `EventPlanningStatusWriter` — isolates the `FAILED` status write in its own
  `REQUIRES_NEW` transaction (see above).

## How it connects

- Entry point is `EventController.generateAssignments`, calling
  `AutoAssignmentService.generate`.
- Delegates persistence entirely to
  [`event/assignment`](../assignment/README.md) — this package never touches
  `TripRepository` directly.
- Distance/duration always flows through `common.geo.routing.RouteEstimateService`
  (injected as a `RouteDistanceMeter` lambda), never `DistanceCalculator`
  directly, except as the tests' default overload.
- Reads/writes `EventEntity.planningStatus`
  (`common.enums.EventPlanningStatus`) and filters on
  `common.enums.ParticipantStatus`.
