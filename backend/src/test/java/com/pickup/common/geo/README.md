# common/geo (tests)

Unit tests for the Haversine distance calculator and the shared location
validator.

## What's tested

- `DistanceCalculatorTest` — same point is exactly 0; NYC-to-LA is within the
  expected ~3,940 km range; the `GeoPoint` overload matches the raw-coordinate
  overload.
- `GeoLocationValidatorTest` — `isComplete` accepts a full triple and rejects any
  partial/blank/out-of-range combination; `requireComplete` throws
  `BadRequestException` on a missing field; `requireCompleteOrAbsent` allows
  all-null and rejects a partial triple.

See also [`routing/`](routing/README.md) for the travel-estimate provider tests.
