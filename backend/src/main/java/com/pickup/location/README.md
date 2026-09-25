# location

Server-side Google Places resolution, used because the Flutter web client's
browser CORS only allows autocomplete requests, not Place Details calls with
field-mask headers.

## What's in it

- `PlacesResolveService` — `resolve(request)`: if a `placeId` is given, tries
  `GET /places/{placeId}` (Place Details, field mask
  `formattedAddress,location`); on any failure (or if no `placeId`), falls back
  to `POST /places:searchText` with the raw autocomplete label. Throws
  `BadRequestException` if the result can't be parsed into a complete
  address+coordinate pair.
- `PlacesProperties` — `pickup.google.places.api-key`; `isConfigured()` gates
  the service (throws `BadRequestException` if unset).
- `PlacesController` — `POST /api/v1/places/resolve`.
- [`dto/`](dto/README.md) — request/response records.

## How it connects

Standalone feature — no other backend package depends on it. Frontend pickup/
destination address pickers call this endpoint after autocomplete selection to
get a canonical address + lat/lng, which then flows into
`event/dto.CreateEventRequest`, `participant/dto` pickup fields, etc. (validated
there by `common/geo/GeoLocationValidator`).
