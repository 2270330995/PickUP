package com.pickup.event.planning;

import com.pickup.common.enums.EventPlanningStatus;
import com.pickup.common.exception.NotFoundException;
import com.pickup.event.EventEntity;
import com.pickup.event.EventRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Persists planning-status transitions in a separate transaction so a FAILED
 * marker survives rollback of the main assignment transaction.
 */
@Component
public class EventPlanningStatusWriter {

    private final EventRepository eventRepository;

    public EventPlanningStatusWriter(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailed(UUID eventId) {
        EventEntity event = eventRepository.findById(eventId)
                .orElseThrow(() -> NotFoundException.of("Event", eventId));
        event.setPlanningStatus(EventPlanningStatus.FAILED);
        eventRepository.save(event);
    }
}
