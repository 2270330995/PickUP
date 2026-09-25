# event/assignment (tests)

Unit tests for `AssignmentService.submit`, mocking `EventService`,
`EventParticipantRepository`, `TripRepository`, and `TripRouteEnrichmentService`,
with a real `TripMapper` (built from real `TripStopMapper` +
`TripNavigationResolver`/`GoogleMapsNavigationUrlBuilder`) so response mapping is
exercised end-to-end.

## What's tested

- `submit_withReadyContactBackedDriver_createsTripWithoutAUserDriver` — a
  Contact-backed driver (no `UserEntity`) produces a trip with `driverId == null`
  but a populated `driverParticipantId` and a display name resolved from the
  Contact; both driver and passenger move to `ASSIGNED`.
- `submit_rejectsDriverWithoutVehicle` — `ConflictException` when the driver has
  no vehicle.
- `submit_rejectsDriverNotYetReadyForAssignment` — `ConflictException` when the
  driver's status isn't in the assignable set.
