package com.pickup.contact.dto;

import com.pickup.common.enums.ParticipantRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateContactRequest(
        @NotBlank @Size(max = 120) String name,
        @Size(max = 40) String phone,
        @Size(max = 160) String email,
        @Size(max = 240) String defaultAddress,
        Double defaultLat,
        Double defaultLng,
        @Size(max = 2000) String notes,
        /** UX hint only; the actual role is decided per event (Phase 4D-2+). Must not be ORGANIZER. */
        ParticipantRole preferredRole
) {}
