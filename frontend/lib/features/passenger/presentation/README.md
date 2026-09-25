# features/passenger/presentation

Passenger-mode trip screen for a user-backed participant tracking their ride.

## Contents

- `passenger_ride_screen.dart` — `PassengerRideScreen(tripId)`: a thin
  wrapper rendering `TripDetailScreen` (`features/trip/presentation`) with
  `TripViewMode.passenger`, app bar title "My ride", and the current user id
  (from `currentUserProvider`, `features/user/data`) so the shared widget can
  highlight the viewer's own stop among the trip's ordered stops.

## How it connects

Routed at `RoutePaths.passengerRide` (`/passenger/rides/:tripId`). See
[`../../trip/presentation/README.md`](../../trip/presentation/README.md) for
the shared trip-detail implementation and
[`features/driver`](../../driver/README.md) for the equivalent driver-mode
wrapper.
