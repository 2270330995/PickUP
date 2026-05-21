package com.pickup.event;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.pickup.common.domain.BaseEntity;
import com.pickup.common.enums.EventPlanningStatus;
import com.pickup.common.enums.EventStatus;
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

@Entity
@Table(name = "events")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class EventEntity extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organizer_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_events_organizer"))
    private UserEntity organizer;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "text")
    private String description;

    @Column(name = "destination_address", nullable = false)
    private String destinationAddress;

    @Column(name = "destination_lat", nullable = false)
    private double destinationLat;

    @Column(name = "destination_lng", nullable = false)
    private double destinationLng;

    @Column(name = "event_time", nullable = false)
    private Instant eventTime;

    /** Lifecycle status only. Planning lives in {@link #planningStatus}. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    @Builder.Default
    private EventStatus status = EventStatus.DRAFT;

    /** Orthogonal to lifecycle. Tracks auto-assignment progress. */
    @Enumerated(EnumType.STRING)
    @Column(name = "planning_status", nullable = false, length = 32)
    @Builder.Default
    private EventPlanningStatus planningStatus = EventPlanningStatus.NOT_STARTED;

    @Column(name = "assignment_generated", nullable = false)
    @Builder.Default
    private boolean assignmentGenerated = false;
}
