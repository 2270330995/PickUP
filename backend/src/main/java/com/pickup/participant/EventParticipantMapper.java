package com.pickup.participant;

import com.pickup.contact.ContactEntity;
import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.EventParticipantResponse.VehicleSummary;
import com.pickup.user.UserEntity;
import com.pickup.vehicle.VehicleEntity;
import org.springframework.stereotype.Component;

@Component
public class EventParticipantMapper {

    public EventParticipantResponse toResponse(EventParticipantEntity entity) {
        VehicleEntity vehicle = entity.getVehicle();
        UserEntity user = entity.getUser();
        ContactEntity contact = entity.getContact();
        return new EventParticipantResponse(
                entity.getId(),
                entity.getEvent().getId(),
                user == null ? null : user.getId(),
                contact == null ? null : contact.getId(),
                ParticipantDisplayResolver.displayName(entity),
                ParticipantDisplayResolver.displayEmail(entity),
                user == null ? null : user.getFullName(),
                user == null ? null : user.getEmail(),
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
