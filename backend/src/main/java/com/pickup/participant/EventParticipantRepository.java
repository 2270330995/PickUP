package com.pickup.participant;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Repository
public interface EventParticipantRepository extends JpaRepository<EventParticipantEntity, UUID> {

    List<EventParticipantEntity> findAllByEventId(UUID eventId);

    List<EventParticipantEntity> findAllByEventIdOrderByCreatedAtAsc(UUID eventId);

    List<EventParticipantEntity> findAllByUserId(UUID userId);

    Optional<EventParticipantEntity> findByEventIdAndUserId(UUID eventId, UUID userId);

    boolean existsByEventIdAndUserId(UUID eventId, UUID userId);

    long countByEventId(UUID eventId);

    @Query("""
            select p.event.id as eventId, count(p) as total
              from EventParticipantEntity p
             where p.event.id in :eventIds
             group by p.event.id
            """)
    List<EventParticipantCountProjection> countParticipantsByEventIds(@Param("eventIds") Set<UUID> eventIds);

    interface EventParticipantCountProjection {
        UUID getEventId();
        long getTotal();
    }
}
