package com.pickup.participant.dto;

import com.pickup.common.enums.ParticipantRole;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

/**
 * Organizer-driven edit of a participant's per-event role and pickup location.
 * All fields are optional; omitted ({@code null}) fields are left unchanged.
 * When any pickup field is supplied, all three must be supplied together.
 *
 * <p>Vehicle selection remains a dedicated concern of the existing
 * {@code PATCH /{participantId}/vehicle} endpoint (now organizer-callable too).
 * These edits are event-local and never write back to the underlying Contact.
 */
public record OrganizerUpdateParticipantRequest(
        ParticipantRole role,
        @Size(max = 500) String pickupAddress,
        @DecimalMin("-90") @DecimalMax("90") Double pickupLat,
        @DecimalMin("-180") @DecimalMax("180") Double pickupLng
) {}
