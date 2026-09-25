# vehicle (tests)

Unit tests for `VehicleService`, mocking `VehicleRepository`, `ContactService`,
`TripRepository`, and `EventParticipantRepository`.

## What's tested

- `createForContact` — saves a vehicle owned by the given Contact.
- `listForContact` — verifies contact ownership before querying vehicles at all
  (`findAllByContactIdOrderByCreatedAtAsc` is never called if the contact check
  fails).
- `updateVehicle` — rejects a seat-count change while the vehicle is referenced
  by an existing trip; throws `NotFoundException` when the vehicle belongs to a
  different contact.
- `deleteVehicle` — rejects deletion while trip-referenced; on success, clears
  the vehicle's per-event participant linkage before deleting the vehicle
  record.
