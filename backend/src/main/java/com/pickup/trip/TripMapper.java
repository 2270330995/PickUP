package com.pickup.trip;

import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.ParticipantDisplayResolver;
import com.pickup.trip.dto.TripResponse;
import com.pickup.trip.dto.TripResponse.VehicleSummary;
import com.pickup.trip.navigation.TripNavigationResolver;
import com.pickup.trip.navigation.TripNavigationResolver.NavigationInfo;
import com.pickup.tripstop.TripStopEntity;
import com.pickup.tripstop.TripStopMapper;
import com.pickup.user.UserEntity;
import com.pickup.vehicle.VehicleEntity;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;

@Component
public class TripMapper {

    private final TripStopMapper stopMapper;
    private final TripNavigationResolver navigationResolver;

    public TripMapper(TripStopMapper stopMapper,
                      TripNavigationResolver navigationResolver) {
        this.stopMapper = stopMapper;
        this.navigationResolver = navigationResolver;
    }

    public TripResponse toResponse(TripEntity entity) {
        VehicleEntity vehicle = entity.getVehicle();
        List<TripStopEntity> stops = entity.getStops();
        NavigationInfo nav = navigationResolver.resolve(entity);
        UserEntity driver = entity.getDriver();
        EventParticipantEntity driverParticipant = entity.getDriverParticipant();
        String driverFullName = driver != null
                ? driver.getFullName()
                : (driverParticipant != null ? ParticipantDisplayResolver.displayName(driverParticipant) : "");
        return new TripResponse(
                entity.getId(),
                entity.getEvent().getId(),
                entity.getEvent().getTitle(),
                entity.getEvent().getEventTime(),
                driver == null ? null : driver.getId(),
                driverFullName,
                driverParticipant == null ? null : driverParticipant.getId(),
                vehicle.getId(),
                new VehicleSummary(
                        vehicle.getId(),
                        vehicle.getMake(),
                        vehicle.getModel(),
                        vehicle.getColor(),
                        vehicle.getPlate(),
                        vehicle.getSeats()),
                entity.getStatus(),
                entity.getCurrentStop() == null ? null : entity.getCurrentStop().getId(),
                entity.getFinalDestinationAddress(),
                entity.getFinalDestinationLat(),
                entity.getFinalDestinationLng(),
                entity.getEncodedPolyline(),
                entity.getStartedAt(),
                entity.getCompletedAt(),
                stops.stream()
                        .sorted(Comparator.comparingInt(TripStopEntity::getSequence))
                        .map(stopMapper::toSummary)
                        .toList(),
                nav.targetType(),
                nav.label(),
                nav.url()
        );
    }
}
