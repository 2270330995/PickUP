package com.pickup.tripstop;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TripStopRepository extends JpaRepository<TripStopEntity, UUID> {
    List<TripStopEntity> findAllByTripIdOrderBySequenceAsc(UUID tripId);
}
