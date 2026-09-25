# contact (tests)

Unit tests for `ContactService`, mocking `ContactRepository`, `UserRepository`,
and `VehicleRepository`.

## What's tested

- `createContact` — saves with organizer/defaults; rejects `preferredRole ==
  ORGANIZER`; rejects an incomplete default-location triad.
- `listContacts` — maps a denormalized vehicle count per contact.
- `getContact` — 404s for an archived contact and for a contact owned by a
  different organizer.
- `updateContact` — a blank string clears an optional field; touching one
  location field re-validates the full triad.
- `archiveContact` — idempotent (archiving twice keeps the original timestamp).
- `requireActiveContact` — 404s when missing.

No custom fixtures beyond an inline `activeContact(name)` helper.
