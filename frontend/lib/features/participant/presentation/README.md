# features/participant/presentation

Small location-picker bottom sheets specific to participant pickup/trip-start
editing.

## Contents

- `pickup_address_sheet.dart`
  - `showPickupAddressSheet(...)` — passenger's pickup location, wraps
    `showLocationPickerSheet` (`features/location/presentation`) and returns
    a `PickupAddressResult {pickupAddress, pickupLat, pickupLng}`.
  - `showTripStartAddressSheet(...)` — driver's route start location, same
    underlying picker with different copy, also returning
    `PickupAddressResult`.

## How it connects

Both are called from
`features/event/presentation/event_detail_screen.dart`'s
`_MyParticipationCard`, feeding `ParticipantApi.setPickup`/`setTripStart`
(`features/participant/data`). Thin wrappers over
[`features/location`](../../location/README.md) — see its README for the
underlying autocomplete widget.
