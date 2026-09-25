# features/people

The organizer's reusable Contact roster: drivers and passengers saved once
and reused across events, with a default pickup address and vehicles, and no
PickUp login of their own. This is the "Contacts" side of the organizer-first
model described in the repo's `CLAUDE.md`.

## Subdirectories

- [`data/`](data/README.md) — `ContactApi` and `ContactResponse`/
  `ContactVehicleResponse` DTOs.
- [`presentation/`](presentation/README.md) — `PeopleListScreen`,
  `ContactFormScreen`, `ContactDetailScreen`, `ContactVehicleFormSheet`.

## How it connects

Feeds `features/event/presentation`'s "Add from People" flow, which creates
Contact-backed `EventParticipant` rows (see
[`features/participant`](../participant/README.md)). Routed at `/people`,
`/people/new`, `/people/:id`, `/people/:id/edit`.
