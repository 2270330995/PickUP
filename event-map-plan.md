# Event map: destination + participants, color-grouped by driver

## Context

The organizer (and participants) currently have no way to see where everyone
actually is relative to the event destination and to each other — the app
only shows addresses as text (in the participant list, the pickup-address
field, and the assignment-management screen's numbered stop lists). The user
wants a map view marking the destination and every participant's pickup
location, with markers color-grouped by which driver they're assigned to, so
it's visually obvious who's riding with whom and how the geography lines up.

They're also planning ahead: a future feature might add live location
sharing. Nothing here builds that — it's out of scope for this change — but
the design keeps it easy to add later by keeping "where is everyone right
now" as a self-contained data-building step, so a live-updating data source
could eventually be swapped in without reworking the map-rendering code.

Two decisions were made explicitly with the user before designing this:

- **Map provider**: Google Maps (`google_maps_flutter`), matching the
  ecosystem already used for Places/Routes autocomplete — accepted knowing
  this requires new setup (see Prerequisites) beyond what's already
  configured for those APIs.
- **Placement**: a new standalone screen, reached via a button from the event
  detail screen — not embedded into the existing Manage Assignments screen.

Research confirmed no new backend work is needed: `EventResponse` already
carries `destinationLat`/`destinationLng` (required), every
`EventParticipantResponse` already carries nullable `pickupLat`/`pickupLng`,
and `AssignmentPlanResponse.trips` (each a `TripResponse` with `driverId` +
`driverParticipantId` + `stops: List<TripStopSummary>`, each stop carrying
`lat`/`lng`) already gives the exact driver-to-passenger grouping needed for
color-coding. All three are already fetched by existing providers
(`eventDetailProvider`, `eventParticipantsProvider`,
`eventAssignmentPlanProvider`) used elsewhere in this codebase (e.g.
`event_detail_screen.dart`, `manage_assignments_screen.dart`).

## Prerequisites (manual, outside this plan's code changes)

`google_maps_flutter` needs a Google Maps Platform API key wired natively per
platform — this is separate from `GOOGLE_PLACES_API_KEY`/`GOOGLE_ROUTES_API_KEY`
(which are Dart-side REST keys for different APIs). Before this feature will
actually render map tiles:

1. In Google Cloud Console, enable "Maps SDK for Android" and "Maps SDK for
   iOS" (and "Maps JavaScript API" if Flutter web matters here) on the same
   project, with billing enabled.
2. Either widen the existing key's allowed APIs to include these, or mint a
   new key — the user's call, not something I can do from this environment.
3. Add `GOOGLE_MAPS_API_KEY` to `.env.example` as a documented placeholder,
   next to `GOOGLE_PLACES_API_KEY`, purely for discoverability. **This does
   not, by itself, feed the Android build.** The root `.env` file is only
   ever read by `docker-compose.yml`, and only for the backend container —
   nothing in the Flutter/Android/iOS toolchain loads it. Gradle's
   `System.getenv(...)` (used below) sees real shell environment variables
   only. Before `flutter build`/`flutter run` for Android, export the key
   directly in the shell that runs the build, e.g.
   `export GOOGLE_MAPS_API_KEY=your-key-here`, or
   `set -a && source .env && set +a` if you'd rather keep the value in the
   `.env` file and just load it per-shell. Either way this is a manual step
   every build shell needs — this plan does not add any automatic
   `.env`-loading code, since none exists in this project today and adding
   one is out of scope for this change.

I cannot verify actual map-tile rendering from this sandboxed environment (no
Android emulator/iOS simulator toolchain here) — that verification is the
user's to do on a real device/simulator once the key is in place.

## Design

### 1. Dependency + native platform wiring

- `frontend/pubspec.yaml`: add `google_maps_flutter` via
  `flutter pub add google_maps_flutter` (let pub resolve the current stable
  version compatible with this project's Flutter/Dart SDK constraints, rather
  than hand-pinning a version number here).
- `frontend/android/app/src/main/AndroidManifest.xml`: add, inside
  `<application>`:
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="${MAPS_API_KEY}" />
  ```
- `frontend/android/app/build.gradle.kts` (confirmed: this project uses
  Kotlin DSL — there is no `build.gradle`, only `.kts`, and no existing
  build-time-value-injection convention to reuse). Inside the existing
  `defaultConfig { }` block, add:
  ```kotlin
  manifestPlaceholders["MAPS_API_KEY"] = System.getenv("GOOGLE_MAPS_API_KEY") ?: ""
  ```
  If the shell export from Prerequisites hasn't been done, this resolves to
  `""` and the manifest key is blank — Maps will fail to render tiles, not
  crash the build.
- `frontend/ios/Runner/AppDelegate.swift`: add `import GoogleMaps` and call
  `GMSServices.provideAPIKey(...)` in
  `application(_:didFinishLaunchingWithOptions:)`, sourcing the key from an
  Info.plist entry populated via an xcconfig variable (the standard pattern
  for this plugin) rather than hardcoding it.
- If `frontend/web/` exists and web support matters: add the Maps JavaScript
  API `<script>` tag to `web/index.html` with the key.

### 2. Routing + entry point

- `frontend/lib/core/router/route_paths.dart`: add
  `static const eventMap = '/events/:id/map';` and
  `static String eventMapFor(String eventId) => '/events/$eventId/map';`,
  matching the exact existing pattern for `eventTrips`/`eventTripsFor`
  (`route_paths.dart:25,40`).
- `frontend/lib/core/router/app_router.dart`: add a
  `GoRoute(path: RoutePaths.eventMap, builder: (_, state) => EventMapScreen(eventId: state.pathParameters['id']!))`,
  matching the existing `eventTrips` route registration
  (`app_router.dart:143-144`).
- `frontend/lib/features/event/presentation/event_detail_screen.dart`: this
  is not a drop-in button add. `EventDetailScreen` (the `ConsumerWidget`
  owning the `Scaffold`/`AppBar`, lines 25-62) builds the `AppBar` before any
  async data resolves. `isOrganizer`, `hasJoined`, and `myParticipant` are
  local variables computed three nesting levels deeper, inside a different
  widget (`_EventDetailBody`'s `me.when(data: ...)` at line 78 and
  `participantsAsync.when(data: ...)` at line 88) — the `AppBar` has no
  access to them as written.

  Fix: have `EventDetailScreen.build` watch the same two providers
  `_EventDetailBody` already watches — `currentUserProvider` and
  `eventParticipantsProvider(eventId)` — directly, alongside the
  `eventDetailProvider(eventId)` it already watches. Riverpod caches provider
  state, so a second widget watching the same provider doesn't trigger a
  second fetch; it just gives `EventDetailScreen` its own read of the same
  data. Gate on `.valueOrNull` from all three, defaulting to hidden while
  anything is still loading:
  ```dart
  bool _canViewEventMap({
    required EventResponse? event,
    required UserResponse? currentUser,
    required List<EventParticipantResponse>? participants,
  }) {
    if (event == null || currentUser == null || participants == null) return false;
    if (currentUser.id == event.organizerId) return true;
    EventParticipantResponse? mine;
    for (final p in participants) {
      if (p.userId == currentUser.id) { mine = p; break; }
    }
    return mine != null &&
        mine.role != ParticipantRole.organizer &&
        _EventDetailBody._canViewEventTrips(mine.status);
  }
  ```
  (`_canViewEventTrips` is already `static` on `_EventDetailBody`; Dart
  privacy is per-file, not per-class, so it's callable from
  `EventDetailScreen` in the same file without moving or duplicating it.)

  Add to `AppBar.actions`:
  ```dart
  actions: [
    if (_canViewEventMap(
        event: eventAsync.valueOrNull,
        currentUser: ref.watch(currentUserProvider).valueOrNull,
        participants: ref.watch(eventParticipantsProvider(eventId)).valueOrNull))
      IconButton(
        icon: const Icon(Icons.map_outlined),
        tooltip: 'Map',
        onPressed: () => context.push(RoutePaths.eventMapFor(eventId)),
      ),
  ],
  ```
  This keeps `EventDetailScreen` a plain `ConsumerWidget` — no
  `StatefulWidget` conversion, no new provider, no moving the `AppBar` — just
  watching two more of the already-existing providers at the higher scope.

### 3. Pure marker-building logic (testable, no plugin dependency)

New file `frontend/lib/features/event/presentation/event_map_markers.dart`,
deliberately independent of `google_maps_flutter` types so it's
unit-testable without a running Flutter engine or platform channels:

```dart
enum EventMapMarkerKind { destination, driver, passenger, unassigned }

class EventMapMarkerSpec {
  const EventMapMarkerSpec({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    required this.kind,
    this.colorGroupIndex, // null for destination/unassigned; index into the palette otherwise
  });
  final String id;
  final double lat;
  final double lng;
  final String label;
  final EventMapMarkerKind kind;
  final int? colorGroupIndex;
}

List<EventMapMarkerSpec> buildEventMapMarkers({
  required EventResponse event,
  required List<EventParticipantResponse> participants,
  required AssignmentPlanResponse plan,
}) {
  // 1. Always include the destination marker.
  // 2. For each trip in plan.trips (index = colorGroupIndex):
  //    - find the driver's own participant by matching EITHER
  //      trip.driverParticipantId == participant.id (contact-backed driver)
  //      OR trip.driverId == participant.userId (legacy self-joined driver)
  //      for their pickup/trip-start marker (skip if pickupLat/Lng null)
  //    - one marker per stop in trip.stops, using stop.lat/lng directly
  // 3. For every remaining PASSENGER or DRIVER participant not covered by
  //    any trip (i.e. not the organizer/independent-attendee roles, and not
  //    already placed by step 2) that HAS a pickup location: one
  //    EventMapMarkerKind.unassigned marker.
  // 4. Participants with no pickup location set are skipped entirely (not
  //    plottable) — not counted as an error, just omitted.
}
```

Driver lookup detail (this matters because of the organizer-first model — a
trip's driver is either contact-backed, with `driverParticipantId` set and
`driverId` null, or a legacy self-joined user, with `driverId` set and
`driverParticipantId` null; see `TripResponse`, `trip_dtos.dart:250-284`):

```dart
EventParticipantResponse? driverFor(
    TripResponse trip, List<EventParticipantResponse> participants) {
  for (final p in participants) {
    if (trip.driverParticipantId != null && p.id == trip.driverParticipantId) {
      return p;
    }
    if (trip.driverId != null && p.userId == trip.driverId) {
      return p;
    }
  }
  return null;
}
```
Checking only `driverParticipantId` (as an earlier draft of this plan did)
would silently drop the driver's own marker for every trip whose driver is a
legacy self-joined user rather than a Contact.

The color palette (a fixed, ordered list of `google_maps_flutter`
`BitmapDescriptor` hues, e.g. `hueRed`, `hueOrange`, `hueYellow`, `hueGreen`,
`hueCyan`, `hueAzure`, `hueViolet`, `hueMagenta`, `hueRose`, cycling via
modulo if there are more drivers than colors) lives in this same file as a
plain `List<double>` of hue values, so both the map-marker layer and the
legend widget can derive matching colors from the same source
(`HSVColor.fromAHSV(1, hue, 1, 1).toColor()` converts a hue to a Flutter
`Color` for the legend, keeping the two visually in sync without duplicating
a separate `Color` palette).

### 4. The screen

New file `frontend/lib/features/event/presentation/event_map_screen.dart`:

- `ConsumerWidget` watching `eventDetailProvider(eventId)`,
  `eventParticipantsProvider(eventId)`, and
  `eventAssignmentPlanProvider(eventId)`, nesting `.when(...)` calls in the
  same style already used in `_EventDetailBody` (this file doesn't currently
  have a combinator for multiple `AsyncValue`s, so match the existing nested
  pattern rather than introducing a new one).
- On success, call `buildEventMapMarkers(...)`, convert each
  `EventMapMarkerSpec` into a `google_maps_flutter` `Marker` (destination
  gets a distinct hue/icon regardless of the driver palette; unassigned
  markers get a neutral grey), and render a `GoogleMap` with those markers.
- On map creation, compute a `LatLngBounds` covering every marker + the
  destination and call
  `controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding))`
  so the whole group is visible without manual panning.
- A small legend below/beside the map (colored dot + driver name per group,
  plus a grey dot for "not yet assigned") built from the same palette.

## Tests

New file
`frontend/test/features/event/presentation/event_map_markers_test.dart` —
plain Dart unit tests against `buildEventMapMarkers(...)` (no widget
rendering, no plugin platform channels involved, matching this repo's
existing preference for testing pure logic directly):

1. Destination marker is always present, even with zero participants.
2. A trip's driver and all its passengers get the same `colorGroupIndex`; two
   different trips get different indices.
3. A participant not on any trip (before assignment has run, or genuinely
   unassigned) gets `EventMapMarkerKind.unassigned`, not grouped with any
   driver.
4. A participant with `pickupLat`/`pickupLng` both null is omitted from the
   result entirely (not a crash, not a marker with garbage coordinates).
5. More drivers/trips than palette colors: color indices wrap around via
   modulo rather than throwing.
6. Empty event (no participants, no trips): result is exactly the one
   destination marker.
7. A trip whose driver is a legacy self-joined user (`driverId` set,
   `driverParticipantId` null) still produces a driver marker for that
   participant, matched via `driverId` — not just the `driverParticipantId`
   path exercised by test 2.

## Verification

1. `cd frontend && flutter pub get` after adding the dependency.
2. `cd frontend && flutter analyze` — clean.
3. `cd frontend && flutter test test/features/event/presentation/event_map_markers_test.dart`
   — all pass. These are pure-Dart tests and can be verified from this
   environment.
4. **Cannot be verified here**: actual map tile rendering, marker placement
   on a real map, and camera-bounds fitting all require a real Android
   emulator/iOS simulator/device with a valid, billed Google Maps API key —
   none of which exist in this sandboxed environment. The user should run
   `flutter run` on their own machine after completing the Prerequisites
   section above and confirm the map renders, markers appear in the right
   colors, and the legend matches.
