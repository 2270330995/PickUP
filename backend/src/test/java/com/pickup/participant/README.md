# participant (tests)

Unit tests for `EventParticipantService` (mocking `EventParticipantRepository`,
`EventService`, `UserRepository`, `ContactService`, `VehicleService`) and for the
standalone `ParticipantDisplayResolver`.

## What's tested

- `EventParticipantServiceTest`:
  - `addFromContact` — happy path copies the Contact's default pickup location
    and lands the participant at `READY`; rejects a duplicate active Contact;
    reactivates a previously-`CANCELLED` row; rejects a vehicle from a different
    Contact; rejects a vehicle on a non-`DRIVER` role.
  - `addFromContacts` — a duplicate Contact within one batch is rejected before
    the second entry is ever saved (the transactional all-or-nothing rollback
    itself is left to Spring's `@Transactional`, out of scope for this
    repository-mocked test).
  - `organizerUpdate` — changes role and pickup; rejects editing an already-
    `ASSIGNED` participant.
  - `remove` — soft-cancels (never calls `delete`); blocked while `ASSIGNED`.
- `ParticipantDisplayResolverTest` — `displayName`/`displayEmail` prefer the
  Contact over the User when both could apply, fall back to the User when
  Contact-backed is not the case, and return `null` for a Contact without an
  email on file; `priorAssignableStatus` is `READY` for Contact-backed and
  `CONFIRMED` for user-backed participants.
