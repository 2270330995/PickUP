# features/vehicle/data

API client and DTOs for the legacy user-owned vehicle "garage" — vehicles
belonging directly to a logged-in user, as opposed to vehicles owned by a
Contact (`features/people/data/contact_dtos.dart`'s
`ContactVehicleResponse`), which is the organizer-first equivalent.

## Contents

- `vehicle_api.dart` (`VehicleApi`, all under `/vehicles`)
  - `listMine()` — `GET /vehicles`.
  - `create(CreateVehicleRequest)` — `POST /vehicles`.
  - `update(id, UpdateVehicleRequest)` — `PATCH /vehicles/{id}`.
  - `delete(id)` — `DELETE /vehicles/{id}`.
  - `vehicleApiProvider`, `myVehiclesProvider` (`FutureProvider.autoDispose`).
- `vehicle_dtos.dart` — `VehicleResponse` (make/model/color/plate/seats,
  `displayLabel`), `CreateVehicleRequest`, `UpdateVehicleRequest`.

## How it connects

Backs `features/vehicle/presentation`'s garage screens and
`vehicle_picker_sheet.dart`, used from
`features/event/presentation/event_detail_screen.dart` when a legacy
user-backed driver picks their vehicle for an event (Contact-backed drivers
use `contactVehiclesProvider` instead — see
[`features/people/data`](../../people/data/README.md)).
