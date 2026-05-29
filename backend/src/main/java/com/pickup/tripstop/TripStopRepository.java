package com.pickup.tripstop;

import com.pickup.common.enums.StopStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TripStopRepository extends JpaRepository<TripStopEntity, UUID> {

    List<TripStopEntity> findAllByTripIdOrderBySequenceAsc(UUID tripId);

    Optional<TripStopEntity> findFirstByParticipantIdAndTripEventId(UUID participantId, UUID eventId);

    /**
     * Trip stops belonging to a participant whose underlying user is the given user, scoped to one event.
     * Used by {@code GET /users/me/trips} to surface trips where the caller is a passenger.
     */
    List<TripStopEntity> findAllByParticipantUserId(UUID userId);

    /**
     * Lowest-sequence stop on the given trip with the requested status. Used during trip execution
     * to find the next stop to activate ({@link StopStatus#PENDING}) or to detect a still-active
     * stop ({@link StopStatus#ACTIVE}) for completion guards.
     */
    Optional<TripStopEntity> findFirstByTripIdAndStatusOrderBySequenceAsc(UUID tripId, StopStatus status);
}
