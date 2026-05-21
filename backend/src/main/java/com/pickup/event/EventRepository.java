package com.pickup.event;

import com.pickup.common.enums.EventStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EventRepository extends JpaRepository<EventEntity, UUID> {

    List<EventEntity> findAllByOrganizerId(UUID organizerId);

    List<EventEntity> findAllByOrganizerIdOrderByEventTimeAsc(UUID organizerId);

    List<EventEntity> findAllByStatusOrderByEventTimeAsc(EventStatus status);
}
