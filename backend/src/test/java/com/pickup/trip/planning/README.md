# trip/planning (tests)

Unit test for the ETA-rounding helper.

## What's tested

- `TripRouteEnrichmentServiceTest` — `toEtaMinutes` rounds a cumulative-seconds
  duration up to whole minutes (1 second and 59 seconds both round up to 1
  minute; 60 seconds stays 1 minute; 61 seconds rounds up to 2).
