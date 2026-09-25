# tripstop

A single ordered pickup stop on a trip.

## What's in it

- `TripStopEntity` — `trip` (`@JsonIgnore` back-reference, breaks the
  `TripEntity`<->`TripStopEntity` serialization cycle), `participant` (the
  passenger), `sequence` (unique per trip via `uk_trip_stops_trip_sequence`),
  `address`, optional `meetingPointName`, `lat`/`lng`, `status` (`StopStatus`,
  defaults `PENDING`), `etaMinutes` (set by
  `trip/planning/TripRouteEnrichmentService`), `actualArrivalTime`/
  `actualDepartureTime` (best-effort, stamped by `TripExecutionService` when a
  stop resolves), and a `navigationLink` placeholder column (unused — navigation
  is computed at read time by `trip/navigation` instead).
- `TripStopMapper` — entity -> `TripResponse.TripStopSummary`, resolving the
  passenger's display name via `ParticipantDisplayResolver`.
- `TripStopRepository` — `findAllByTripIdOrderBySequenceAsc`,
  `findAllByParticipantUserId` (used by `TripService.listMyTrips` to find trips
  where the caller is a passenger), and
  `findFirstByTripIdAndStatusOrderBySequenceAsc` (the core query
  `TripExecutionService` uses to find the next `PENDING` stop to activate, or to
  detect a stray `ACTIVE` stop).

## How it connects

Created exclusively by `event/assignment/AssignmentService.submit` (one row per
passenger in a driver's plan, in organizer/auto-assignment order). Mutated only
by `trip/TripExecutionService` during trip execution. Read by `trip/TripMapper`
(via `TripStopMapper`) to build each `TripResponse`.
