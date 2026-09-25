# features/vehicle/presentation

Screens for a logged-in user's own vehicle garage (legacy self-join path).

## Contents

- `vehicle_list_screen.dart` — `VehicleListScreen`: lists `myVehiclesProvider`
  with edit/delete (delete behind a confirmation dialog), FAB to add.
- `vehicle_form_screen.dart` — `VehicleFormScreen({existing})`: single
  create/edit form (make, model, color, plate, seats 1-15).
- `vehicle_picker_sheet.dart` — `showVehiclePickerSheet(...)`: bottom sheet
  for a driver to pick (or clear) which of their vehicles to use for a
  specific event; returns a `VehicleSheetResult` distinguishing "cleared" from
  "dismissed". Offers a shortcut to `vehicleNew` when the user has no
  vehicles yet.

## How it connects

Built on `features/vehicle/data`. Routed at `RoutePaths.vehicles`,
`vehicleNew`, `vehicleEdit`; linked from
`features/profile/presentation/profile_screen.dart` ("My vehicles").
`vehicle_picker_sheet.dart` is invoked from
`features/event/presentation/event_detail_screen.dart` for legacy
user-backed drivers. See [`../data/README.md`](../data/README.md).
