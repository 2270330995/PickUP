package com.pickup.participant.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/**
 * Bulk add payload. Processed atomically: if any entry fails (duplicate,
 * archived contact, invalid vehicle, etc.), the entire batch is rolled back.
 */
public record AddContactsFromRosterRequest(
        @NotEmpty @Valid List<AddContactParticipantRequest> entries
) {}
