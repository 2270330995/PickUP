# features/people/presentation

Screens for managing the organizer's People (Contact) roster and each
contact's vehicles.

## Contents

- `people_list_screen.dart` — `PeopleListScreen`: lists `contactsProvider`
  as cards (name, phone, default address, preferred-role chip, vehicle
  count), FAB to add a new person.
- `contact_form_screen.dart` — `ContactFormScreen({existing})`: single form
  for both create and edit (branches on whether `existing` is supplied).
  Fields: name, preferred role hint (driver/passenger/independent attendee —
  never organizer), phone, email, default location
  (`AddressAutocompleteField`, `features/location`), notes. Only sends
  location fields when Places resolved a full address+lat+lng triad, to
  avoid clearing an address while leaving stale coordinates.
- `contact_detail_screen.dart` — `ContactDetailScreen(contactId)`: contact
  info card, vehicle list with add/edit/delete (via
  `ContactVehicleFormSheet`), and an archive action (soft-delete via
  `ContactApi.archive`, with a confirmation dialog).
- `contact_vehicle_form_sheet.dart` — `ContactVehicleFormSheet` bottom sheet:
  create/edit a Contact-owned vehicle (label, make, model, color, plate,
  seats 1-15, notes).

## How it connects

Built entirely on `features/people/data`'s `ContactApi`/providers. Routed at
`RoutePaths.people`, `peopleNew`, `peopleDetail`, `peopleEdit`. Linked from
`features/organizer/presentation/organizer_dashboard_screen.dart` (People
shortcut) and consumed by `features/event/presentation` when adding Contacts
to an event. See [`../data/README.md`](../data/README.md) for the API
contract.
