# features/assignment

Organizer-facing capability: build and save the driver-passenger assignment
plan for an event, either manually or by running the backend's
auto-assignment pipeline.

## Subdirectories

- [`data/`](data/README.md) — `AssignmentApi` (get plan / submit plan /
  generate assignments) and the `AssignmentPlanResponse`/
  `SubmitAssignmentsRequest` DTOs.
- [`presentation/`](presentation/README.md) — `ManageAssignmentsScreen`, the
  drag-free multi-select UI for assigning ready/confirmed passengers to
  drivers with a vehicle, respecting seat capacity.

## How it connects

Sits between `features/participant` (who's eligible), `features/trip` (what
a plan/trip looks like once assigned), and the backend's
`AutoAssignmentService`/`AssignmentService`. Routed at
`/events/:id/assignments` (`RoutePaths.manageAssignments`), linked from
`features/event/presentation/event_detail_screen.dart`.
