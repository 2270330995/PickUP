package com.pickup.participant;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.pickup.common.domain.BaseEntity;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.contact.ContactEntity;
import com.pickup.event.EventEntity;
import com.pickup.user.UserEntity;
import com.pickup.vehicle.VehicleEntity;
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

import java.util.UUID;

/**
 * A participant row originates from exactly one identity source: a registered
 * {@link UserEntity} (legacy self-join) or an organizer-owned {@link ContactEntity}
 * (Phase 4D-2 organizer-added participant). The database enforces this exclusivity
 * via {@code chk_participants_user_xor_contact} plus partial unique indexes on
 * {@code (event_id, user_id)} and {@code (event_id, contact_id)}.
 */
@Entity
@Table(name = "event_participants")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class EventParticipantEntity extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_participants_event"))
    private EventEntity event;

    /** Set for legacy self-joined participants; null for Contact-backed rows. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id",
            foreignKey = @ForeignKey(name = "fk_participants_user"))
    private UserEntity user;

    /** Set for organizer-added participants (Phase 4D-2+); null for legacy self-joins. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contact_id",
            foreignKey = @ForeignKey(name = "fk_participants_contact"))
    private ContactEntity contact;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private ParticipantRole role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    @Builder.Default
    private ParticipantStatus status = ParticipantStatus.INVITED;

    @Column(name = "pickup_address")
    private String pickupAddress;

    @Column(name = "pickup_lat")
    private Double pickupLat;

    @Column(name = "pickup_lng")
    private Double pickupLng;

    /** Only meaningful when {@code role == DRIVER}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id",
            foreignKey = @ForeignKey(name = "fk_participants_vehicle"))
    private VehicleEntity vehicle;
}
