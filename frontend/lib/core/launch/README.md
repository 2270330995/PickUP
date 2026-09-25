# core/launch

Wraps external URL launching (deep links to other apps) with user-facing
error feedback.

## Contents

- `external_url_launcher.dart` — `launchExternalUrl(BuildContext, String
  url)`: parses the URL, checks `canLaunchUrl`, and calls `launchUrl` in
  `LaunchMode.externalApplication`. On any failure (invalid URL, no handling
  app, or a thrown exception) it shows a `SnackBar` with a user-readable
  message instead of throwing.

## How it connects

Used wherever the app opens a deep link outside itself — chiefly the driver
trip-navigation flow, where `TripNavigationResolver`/
`GoogleMapsNavigationUrlBuilder` on the backend produce a Google Maps URL
that `features/driver/presentation/driver_trip_screen.dart` and related trip
screens hand to this helper. Depends on the `url_launcher` package only; no
Riverpod providers.
