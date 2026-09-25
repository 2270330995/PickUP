# features/event/presentation

The event lifecycle screens: browsing/creating events, and the central event
detail screen where both organizers and participants manage everything about
one event.

## Contents

- `browse_events_screen.dart` — `BrowseEventsScreen`: lists `openEventsProvider`
  (events the viewer can self-join), tapping through to event detail.
- `create_event_screen.dart` — `CreateEventScreen`: title/description/
  destination (via `AddressAutocompleteField`, `features/location`)/date-time
  form; calls `EventApi.create`, invalidates `myEventsProvider` and
  `organizerDashboardProvider`, then navigates to the new event's detail
  screen.
- `event_detail_screen.dart` — `EventDetailScreen(eventId)`: the largest
  screen in the app. Shows, depending on viewer role:
  - The viewer's own participation card (`_MyParticipationCard`) with role,
    status, vehicle (drivers)/pickup address (passengers)/trip-start
    location, confirm/cancel actions, and a link into their own trip once
    assigned.
  - A "Join this event" card for open events the viewer hasn't joined
    (legacy self-join path).
  - A dashboard snapshot (`eventDashboardProvider`,
    `features/dashboard/data`).
  - Organizer-only actions (`_OrganizerActions`): auto-assign, manage
    assignments, view event trips, close/reopen/cancel/delete the event.
  - The full participant roster with organizer moderation actions
    (approve/reject/edit/remove) via `organizer_participant_edit_sheet.dart`
    and `add_from_people_sheet.dart`.
- `add_from_people_sheet.dart` — `showAddFromPeopleSheet(...)`: organizer-only
  bottom sheet to bulk-add Contacts from the People roster
  (`features/people/data`) to the event, choosing per-contact role and
  (for drivers) vehicle, submitted atomically via
  `ParticipantApi.addFromContacts`. Added contacts land as `READY`
  immediately (no approval step), per the organizer-first model.
- `organizer_participant_edit_sheet.dart` — `showOrganizerParticipantEditSheet(...)`:
  organizer-only bottom sheet to edit a participant's per-event role, pickup
  location, and (for Contact-backed drivers) vehicle. Explicitly event-local
  — never writes back to the underlying Contact.

## How it connects

Depends on `features/event/data` (event CRUD), `features/participant/data`
(roster mutations), `features/people/data` (Contact roster for
add-from-people), `features/vehicle`/`features/location` (pickup/vehicle
pickers), `features/dashboard/data` (snapshot), and
`features/assignment/data` (auto-assign trigger from the detail screen).
Routed at `RoutePaths.browseEvents`, `createEvent`, and `eventDetail`. See
[`../data/README.md`](../data/README.md) for the underlying API contract.
