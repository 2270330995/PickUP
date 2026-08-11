package com.pickup.event.assignment.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

/**
 * Full-replace manual-assignment plan submitted by an event organizer.
 *
 * <p>Every confirmed driver the organizer wants to keep in the plan must be present
 * (even with an empty passenger list). Drivers omitted from this list will be
 * unassigned and any prior trip of theirs deleted. The same holds for passengers:
 * passengers not appearing in any driver's list are removed from trip planning
 * (status reverts CONFIRMED).
 */
public record SubmitAssignmentsRequest(
        @NotNull @Valid List<DriverAssignment> assignments
) {
    public record DriverAssignment(
            @NotNull UUID driverParticipantId,
            @NotNull List<UUID> passengerParticipantIds
    ) {}
}
