# features/event

Core event lifecycle: create an event, browse/join open events, and manage
everything about one event (participants, assignments, lifecycle status)
from its detail screen. This is the hub feature most other features link
into.

## Subdirectories

- [`data/`](data/README.md) — `EventApi` and `EventResponse`/
  `CreateEventRequest`/`UpdateEventRequest` DTOs.
- [`presentation/`](presentation/README.md) — `BrowseEventsScreen`,
  `CreateEventScreen`, `EventDetailScreen`, plus the
  add-from-people and organizer-participant-edit bottom sheets.

## How it connects

Ties together `features/participant` (roster), `features/assignment`
(planning), `features/dashboard` (summaries), `features/people`/`vehicle`/
`location` (roster/vehicle/address pickers used from the detail screen), and
`features/trip` (links into a participant's own trip or an event's trip
list). Routed at `/events`, `/events/new`, `/events/:id`
(`RoutePaths.browseEvents`/`createEvent`/`eventDetail`).
