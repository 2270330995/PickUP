# location/dto

Request/response records for server-side place resolution.

## What's in it

- `ResolvePlaceRequest` — optional `placeId` (from client-side autocomplete),
  required `query` (fallback text), optional `sessionToken` (Google Places
  billing session).
- `ResolvedPlaceResponse` — `formattedAddress`, `lat`, `lng`.

## How it connects

Consumed by `PlacesController` and produced by `PlacesResolveService` in the
parent `location/` package.
