package com.pickup.participant;

import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.EventParticipantResponse.VehicleSummary;
import com.pickup.vehicle.VehicleEntity;
import org.springframework.stereotype.Component;

@Component
public class EventParticipantMapper {

    public EventParticipantResponse toResponse(EventParticipantEntity entity) {
        VehicleEntity vehicle = entity.getVehicle();
        return new EventParticipantResponse(
                entity.getId(),
                entity.getEvent().getId(),
                entity.getUser().getId(),
                entity.getUser().getFullName(),
                entity.getUser().getEmail(),
                entity.getRole(),
                entity.getStatus(),
                entity.getPickupAddress(),
                entity.getPickupLat(),
                entity.getPickupLng(),
                vehicle == null ? null : vehicle.getId(),
                vehicle == null ? null : new VehicleSummary(
                        vehicle.getId(),
                        vehicle.getMake(),
                        vehicle.getModel(),
                        vehicle.getColor(),
                        vehicle.getPlate(),
                        vehicle.getSeats()),
                entity.getCreatedAt()
        );
    }
}
