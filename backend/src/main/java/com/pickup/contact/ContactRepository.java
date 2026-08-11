package com.pickup.contact;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContactRepository extends JpaRepository<ContactEntity, UUID> {

    List<ContactEntity> findAllByOrganizerIdAndArchivedAtIsNullOrderByNameAsc(UUID organizerId);

    Optional<ContactEntity> findByIdAndOrganizerId(UUID id, UUID organizerId);
}
