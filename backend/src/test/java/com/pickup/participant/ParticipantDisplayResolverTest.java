package com.pickup.participant;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.contact.ContactEntity;
import com.pickup.user.UserEntity;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class ParticipantDisplayResolverTest {

    @Test
    void displayName_and_displayEmail_preferContactOverUser() {
        ContactEntity contact = ContactEntity.builder().name("Dell").email("dell@test.com").build();
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .role(ParticipantRole.PASSENGER).contact(contact).build();

        assertEquals("Dell", ParticipantDisplayResolver.displayName(participant));
        assertEquals("dell@test.com", ParticipantDisplayResolver.displayEmail(participant));
    }

    @Test
    void displayName_and_displayEmail_fallBackToUserWhenNotContactBacked() {
        UserEntity user = UserEntity.builder().fullName("Jane Doe").email("jane@test.com").build();
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .role(ParticipantRole.PASSENGER).user(user).build();

        assertEquals("Jane Doe", ParticipantDisplayResolver.displayName(participant));
        assertEquals("jane@test.com", ParticipantDisplayResolver.displayEmail(participant));
    }

    @Test
    void displayEmail_isNullForContactWithoutAnEmailOnFile() {
        ContactEntity contact = ContactEntity.builder().name("Dell").build();
        EventParticipantEntity participant = EventParticipantEntity.builder()
                .role(ParticipantRole.PASSENGER).contact(contact).build();

        assertNull(ParticipantDisplayResolver.displayEmail(participant));
    }

    @Test
    void priorAssignableStatus_isReadyForContactBacked_confirmedForUserBacked() {
        EventParticipantEntity contactBacked = EventParticipantEntity.builder()
                .role(ParticipantRole.DRIVER)
                .contact(ContactEntity.builder().name("Dell").build())
                .status(ParticipantStatus.ASSIGNED)
                .build();
        EventParticipantEntity userBacked = EventParticipantEntity.builder()
                .role(ParticipantRole.DRIVER)
                .user(UserEntity.builder().fullName("Jane").build())
                .status(ParticipantStatus.ASSIGNED)
                .build();

        assertEquals(ParticipantStatus.READY, ParticipantDisplayResolver.priorAssignableStatus(contactBacked));
        assertEquals(ParticipantStatus.CONFIRMED, ParticipantDisplayResolver.priorAssignableStatus(userBacked));
    }
}
