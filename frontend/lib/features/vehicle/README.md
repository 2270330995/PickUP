# features/vehicle

The legacy user-owned vehicle garage: vehicles a logged-in user owns
directly, for the self-join driver flow. Contact-backed drivers instead use
vehicles owned by their Contact record (see
[`features/people`](../people/README.md)).

## Subdirectories

- [`data/`](data/README.md) — `VehicleApi` and `VehicleResponse`/
  `CreateVehicleRequest`/`UpdateVehicleRequest`.
- [`presentation/`](presentation/README.md) — `VehicleListScreen`,
  `VehicleFormScreen`, `showVehiclePickerSheet`.

## How it connects

Routed at `/vehicles`, `/vehicles/new`, `/vehicles/:id/edit`. Used from
`features/profile` (garage management) and
`features/event/presentation/event_detail_screen.dart` (picking a vehicle
for a legacy user-backed driver participant).
