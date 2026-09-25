# trip/dto

Request/response records for trip reads and driver-issued stop actions.

## What's in it

- `TripResponse` — the full read model: event context (`eventId`, `eventTitle`,
  `eventTime`), driver identity (`driverId` nullable for Contact-backed drivers,
  `driverFullName` resolved from either the user or the participant,
  `driverParticipantId`), vehicle summary, `status` (`TripStatus`),
  `currentStopId`, final destination, `encodedPolyline` (currently always null —
  see `common/geo/routing`), timestamps, the ordered `stops` list
  (`TripStopSummary`), and the computed `navigationTargetType`/`navigationLabel`/
  `navigationUrl` (from `trip/navigation`).
  - Nested `VehicleSummary` and `TripStopSummary` records are embedded so the
    driver/passenger UI can render without follow-up fetches.
- `UpdateTripStopRequest` — a driver's resolution of the currently-active stop:
  `action` is `PICK_UP`, `SKIP`, or `CANCEL`.

## How it connects

Built by `TripMapper`/`TripStopMapper` (`trip/`, `tripstop/`); returned by
`TripController` and embedded inside `event/assignment/dto.AssignmentPlanResponse`.
`UpdateTripStopRequest` is consumed by `TripExecutionService.updateStop`.
