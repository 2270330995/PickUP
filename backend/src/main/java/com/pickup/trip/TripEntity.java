package com.pickup.trip;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.pickup.common.domain.BaseEntity;
import com.pickup.common.enums.TripStatus;
import com.pickup.event.EventEntity;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.tripstop.TripStopEntity;
import com.pickup.user.UserEntity;
import com.pickup.vehicle.VehicleEntity;
import jakarta.persistence.CascadeType;
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
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "trips")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class TripEntity extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_trips_event"))
    private EventEntity event;

    /** Set for legacy trips whose driver is a registered user; null for Contact-backed drivers. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id",
            foreignKey = @ForeignKey(name = "fk_trips_driver"))
    private UserEntity driver;

    /**
     * The driver's {@code EventParticipant} row for this trip. Always set for trips
     * created since Phase 4D-2; legacy trips created before then may have this null
     * with only {@link #driver} populated.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_participant_id",
            foreignKey = @ForeignKey(name = "fk_trips_driver_participant"))
    private EventParticipantEntity driverParticipant;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "vehicle_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_trips_vehicle"))
    private VehicleEntity vehicle;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    @Builder.Default
    private TripStatus status = TripStatus.ASSIGNED;

    /** Active stop driving the step-by-step UI. Nullable until the trip starts. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_stop_id",
            foreignKey = @ForeignKey(name = "fk_trips_current_stop"))
    private TripStopEntity currentStop;

    /** Snapshot of the event destination so the trip remains self-contained. */
    @Column(name = "final_destination_address", nullable = false)
    private String finalDestinationAddress;

    @Column(name = "final_destination_lat", nullable = false)
    private double finalDestinationLat;

    @Column(name = "final_destination_lng", nullable = false)
    private double finalDestinationLng;

    /** Placeholder for future Google Routes API encoded polyline response. */
    @Column(name = "encoded_polyline", columnDefinition = "text")
    private String encodedPolyline;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @OneToMany(mappedBy = "trip", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sequence ASC")
    @Builder.Default
    private List<TripStopEntity> stops = new ArrayList<>();
}
