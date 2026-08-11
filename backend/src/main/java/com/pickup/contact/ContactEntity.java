package com.pickup.contact;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.pickup.common.domain.BaseEntity;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.user.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * A person known to an organizer (driver, passenger, or both across different
 * events), reusable without requiring the person to hold a {@link UserEntity}
 * account. Event-specific role, status, and location overrides live on
 * {@code EventParticipant} (Phase 4D-2+); this entity only stores the
 * organizer's reusable defaults for that person.
 */
@Entity
@Table(name = "contacts")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ContactEntity extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organizer_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_contacts_organizer"))
    private UserEntity organizer;

    @Column(nullable = false)
    private String name;

    @Column
    private String phone;

    @Column
    private String email;

    @Column(name = "default_address")
    private String defaultAddress;

    @Column(name = "default_lat")
    private Double defaultLat;

    @Column(name = "default_lng")
    private Double defaultLng;

    @Column(columnDefinition = "text")
    private String notes;

    /**
     * UX hint only. Where the person is labeled/pre-filled in event flows; their
     * actual event role always lives on {@code EventParticipant.role} (Phase 4D-2+).
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_role", length = 32)
    private ParticipantRole preferredRole;

    /**
     * Reserved for future account-claiming: lets a Contact be linked to a real
     * {@link UserEntity} if that person later registers, without duplicating the
     * person or requiring a shadow account today. Unused until a later phase.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "claimed_by_user_id",
            foreignKey = @ForeignKey(name = "fk_contacts_claimed_by_user"))
    private UserEntity claimedByUser;

    /** Soft-archive marker. Archived contacts are hidden from the roster but never hard-deleted. */
    @Column(name = "archived_at")
    private Instant archivedAt;
}
