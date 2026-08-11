package com.pickup.participant.dto;

import com.pickup.common.enums.ParticipantRole;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * Organizer payload adding a single {@code Contact} to an event as a participant.
 * When {@code pickupAddress}/{@code pickupLat}/{@code pickupLng} are omitted, the
 * contact's default location (if any) is copied in at creation time only.
 */
public record AddContactParticipantRequest(
        @NotNull UUID contactId,
        @NotNull ParticipantRole role,
        UUID vehicleId,
        @Size(max = 500) String pickupAddress,
        @DecimalMin("-90") @DecimalMax("90") Double pickupLat,
        @DecimalMin("-180") @DecimalMax("180") Double pickupLng
) {}
