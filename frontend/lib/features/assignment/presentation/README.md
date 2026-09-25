# features/assignment/presentation

Organizer screen for building an event's driver/passenger assignment plan,
manually or via auto-assignment.

## Contents

- `manage_assignments_screen.dart` — `ManageAssignmentsScreen(eventId)`:
  - Renders one card per assignable driver (`READY`/`CONFIRMED`/`ASSIGNED`
    status, has a vehicle, and whose existing trip — if any — is still in the
    editable `ASSIGNED` state) showing their vehicle, seat capacity, and
    currently chosen passengers via `OrderedParticipantStopPreview`
    (`features/trip/presentation`).
  - "Assign passengers" opens a `_PassengerPickerSheet` bottom sheet to
    multi-select from confirmed/ready passengers not already on another
    driver, capped at `seats - 1`.
  - Maintains local draft state (`driverParticipantId -> ordered
    passengerParticipantIds`) reconciled against the server plan via a seed
    key derived from trip/stop ids, so in-flight edits survive provider
    refetches but reset when the server plan actually changes.
  - "Save plan" calls `AssignmentApi.submit`; "Auto assign" calls
    `AssignmentApi.generateAssignments`. Both invalidate the participant,
    plan, dashboard, event-detail, and my-trips providers afterward.
  - Trips already in a non-`ASSIGNED` status (e.g. in progress/completed) are
    shown read-only as `_LockedTripCard`s and excluded from editing, matching
    the backend's `AssignmentPreservation` exclusion of in-flight trips.

## How it connects

Reads `eventParticipantsProvider` (`features/participant/data`),
`eventAssignmentPlanProvider` (`features/assignment/data`), and
`eventDetailProvider` (`features/event/data`). Routed at
`RoutePaths.manageAssignments` (`/events/:id/assignments`). See
[`../data/README.md`](../data/README.md) for the API/DTO layer this screen
drives.
