package com.pickup.participant;

import com.pickup.participant.dto.EventParticipantResponse;
import org.springframework.stereotype.Component;

@Component
public class EventParticipantMapper {

    public EventParticipantResponse toResponse(EventParticipantEntity entity) {
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
                entity.getVehicle() == null ? null : entity.getVehicle().getId(),
                entity.getCreatedAt()
        );
    }
}
