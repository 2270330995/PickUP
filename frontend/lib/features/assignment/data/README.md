# features/assignment/data

API client and DTOs for building/reading an event's driver-passenger
assignment plan.

## Contents

- `assignment_api.dart`
  - `AssignmentApi.getPlan(eventId)` — `GET /events/{id}/trips`: read-only view
    of existing trips plus confirmed passengers not yet placed on any trip.
  - `AssignmentApi.submit(eventId, SubmitAssignmentsRequest)` — `POST
    /events/{id}/assignments`: atomic full-replace of the plan (backed by
    `AssignmentService.submit()` on the backend).
  - `AssignmentApi.generateAssignments(eventId)` — `POST
    /events/{id}/planning/generate-assignments`: triggers the backend's
    `AutoAssignmentService.generate()` pipeline (organizer only).
  - `assignmentApiProvider` — `Provider<AssignmentApi>` built on `dioProvider`.
  - `eventAssignmentPlanProvider` — `FutureProvider.family<AssignmentPlanResponse,
    String>` (autoDispose) wrapping `getPlan`.
- `assignment_dtos.dart`
  - `DriverAssignmentInput` / `SubmitAssignmentsRequest` — request shapes for
    `submit`: a driver's participant id plus an ordered list of passenger
    participant ids.
  - `AssignmentPlanResponse` — parses `{eventId, trips, unassignedConfirmedPassengerIds}`
    into a list of `TripResponse` (from `features/trip/data/trip_dtos.dart`)
    plus derived getters (`assignedTripCount`, `assignedPassengerCount`,
    `summaryMessage`, `autoAssignSummaryMessage`) used directly in UI
    SnackBars.

## How it connects

Talks to the backend's `event/planning` + `event/assignment` package
(`AutoAssignmentService`, `AssignmentService`). Consumed by
`features/assignment/presentation/manage_assignments_screen.dart`, which also
invalidates `participant`, `dashboard`, `event`, and `trip` providers after a
successful save/generate since assignment changes ripple into all of those.
