package com.pickup.participant;

import com.pickup.common.enums.ParticipantStatus;
import com.pickup.contact.ContactEntity;
import com.pickup.user.UserEntity;

/**
 * Resolves display fields for an {@link EventParticipantEntity} that may be backed
 * by a registered {@link UserEntity} (legacy self-join) or an organizer-owned
 * {@link ContactEntity} (Phase 4D-2 organizer-added participant). Exactly one of
 * {@code user}/{@code contact} is set on any given participant row.
 */
public final class ParticipantDisplayResolver {

    private ParticipantDisplayResolver() {}

    public static String displayName(EventParticipantEntity participant) {
        ContactEntity contact = participant.getContact();
        if (contact != null) {
            return contact.getName();
        }
        UserEntity user = participant.getUser();
        return user != null ? user.getFullName() : "";
    }

    public static String displayEmail(EventParticipantEntity participant) {
        ContactEntity contact = participant.getContact();
        if (contact != null) {
            return contact.getEmail();
        }
        UserEntity user = participant.getUser();
        return user != null ? user.getEmail() : null;
    }

    /**
     * Status an ASSIGNED participant reverts to once unassigned from a trip.
     * Contact-backed participants skip the approval flow and go straight to
     * READY, so they revert to READY rather than a CONFIRMED status they
     * never actually held.
     */
    public static ParticipantStatus priorAssignableStatus(EventParticipantEntity participant) {
        return participant.getContact() != null ? ParticipantStatus.READY : ParticipantStatus.CONFIRMED;
    }
}
