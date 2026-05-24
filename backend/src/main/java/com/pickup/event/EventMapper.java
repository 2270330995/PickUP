package com.pickup.event;

import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.event.dto.EventResponse;
import org.springframework.stereotype.Component;

@Component
public class EventMapper {

    public EventResponse toResponse(EventEntity entity, int participantCount) {
        return toResponse(entity, participantCount, null, null);
    }

    public EventResponse toResponse(EventEntity entity,
                                    int participantCount,
                                    ParticipantRole currentUserRole,
                                    ParticipantStatus currentUserStatus) {
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
                currentUserRole,
                currentUserStatus,
                entity.getCreatedAt()
        );
    }
}
