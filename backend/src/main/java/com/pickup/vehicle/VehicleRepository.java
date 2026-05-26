package com.pickup.vehicle;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VehicleRepository extends JpaRepository<VehicleEntity, UUID> {

    List<VehicleEntity> findAllByOwnerIdOrderByCreatedAtAsc(UUID ownerId);

    List<VehicleEntity> findAllByOwnerId(UUID ownerId);

    Optional<VehicleEntity> findByIdAndOwnerId(UUID id, UUID ownerId);
}
