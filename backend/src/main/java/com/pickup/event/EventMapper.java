package com.pickup.event;

import com.pickup.event.dto.EventResponse;
import org.springframework.stereotype.Component;

@Component
public class EventMapper {

    public EventResponse toResponse(EventEntity entity, int participantCount) {
        return new EventResponse(
                entity.getId(),
                entity.getOrganizer().getId(),
                entity.getOrganizer().getFullName(),
                entity.getTitle(),
                entity.getDescription(),
                entity.getDestinationAddress(),
                entity.getDestinationLat(),
                entity.getDestinationLng(),
                entity.getEventTime(),
                entity.getStatus(),
                entity.getPlanningStatus(),
                entity.isAssignmentGenerated(),
                participantCount,
                entity.getCreatedAt()
        );
    }
}
