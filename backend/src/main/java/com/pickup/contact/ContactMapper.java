package com.pickup.contact;

import com.pickup.contact.dto.ContactResponse;
import org.springframework.stereotype.Component;

@Component
public class ContactMapper {

    public ContactResponse toResponse(ContactEntity entity, int vehicleCount) {
        return new ContactResponse(
                entity.getId(),
                entity.getName(),
                entity.getPhone(),
                entity.getEmail(),
                entity.getDefaultAddress(),
                entity.getDefaultLat(),
                entity.getDefaultLng(),
                entity.getNotes(),
                entity.getPreferredRole(),
                vehicleCount,
                entity.getArchivedAt(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
