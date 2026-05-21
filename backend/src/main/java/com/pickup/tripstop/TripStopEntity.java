package com.pickup.tripstop;

import com.pickup.common.domain.BaseEntity;
import com.pickup.common.enums.StopStatus;
import com.pickup.participant.EventParticipantEntity;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.pickup.trip.TripEntity;
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
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(
        name = "trip_stops",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_trip_stops_trip_sequence",
                columnNames = {"trip_id", "sequence"}
        )
)
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class TripStopEntity extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    /** Back-reference — excluded from serialization to break the TripEntity↔TripStopEntity cycle. */
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_trip_stops_trip"))
    private TripEntity trip;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "participant_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_trip_stops_participant"))
    private EventParticipantEntity participant;

    @Column(nullable = false)
    private int sequence;

    @Column(nullable = false)
    private String address;

    /** Optional human-readable meeting point label (e.g. "Main Lobby", "North Gate"). */
    @Column(name = "meeting_point_name")
    private String meetingPointName;

    @Column(nullable = false)
    private double lat;

    @Column(nullable = false)
    private double lng;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    @Builder.Default
    private StopStatus status = StopStatus.PENDING;

    @Column(name = "eta_minutes")
    private Integer etaMinutes;

    @Column(name = "actual_arrival_time")
    private Instant actualArrivalTime;

    @Column(name = "actual_departure_time")
    private Instant actualDepartureTime;

    /** Placeholder for future Google Maps deep link. Populated in a later phase. */
    @Column(name = "navigation_link", columnDefinition = "text")
    private String navigationLink;
}
