# vehicle/dto

Request/response records for a Contact's vehicles.

## What's in it

- `CreateVehicleRequest` — optional `label` (e.g. "Craig's Honda"), required
  `make`/`model`, optional `color`/`plate`/`notes`, required `seats` (1-15).
- `UpdateVehicleRequest` — same fields, all optional (partial update).
- `VehicleResponse` — `id`, `contactId` (the owning Contact, not a User), and the
  vehicle fields plus `createdAt`.

## How it connects

Consumed by `ContactVehicleController` (`contact/`) and the legacy
`VehicleController` (which now always rejects with a redirect message); produced
by `VehicleMapper`/`VehicleService` in the parent `vehicle/` package.
