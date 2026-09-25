# event/assignment/dto

Request/response records for the manual (and auto-generated) assignment plan.

## What's in it

- `SubmitAssignmentsRequest` — full-replace payload: a list of `DriverAssignment`
  (`driverParticipantId` + ordered `passengerParticipantIds`). Every driver the
  organizer wants to keep must be present, even with an empty passenger list;
  omitted drivers/passengers are unassigned.
- `AssignmentPlanResponse` — `eventId`, the resulting `trips` (`TripResponse`
  list, from `trip/dto`), and `unassignedConfirmedPassengerIds`. Returned by both
  the submit endpoint and the read-only plan/trip-list endpoints so the UI can
  render trips plus the leftover pool in one round trip.

## How it connects

Built and consumed entirely within `event/assignment/` (`AssignmentService`) and
`event/planning/` (`AutoAssignmentService`, which constructs a
`SubmitAssignmentsRequest` from its own scoring/ordering output and delegates to
`AssignmentService.submit`). Also read by `trip/TripController` for the
organizer's trip list view.
