package com.pickup.trip;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TripRepository extends JpaRepository<TripEntity, UUID> {
    List<TripEntity> findAllByEventId(UUID eventId);

    List<TripEntity> findAllByDriverId(UUID driverId);
}
