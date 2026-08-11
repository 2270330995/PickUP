package com.pickup.vehicle;

import com.pickup.vehicle.dto.VehicleResponse;
import org.springframework.stereotype.Component;

@Component
public class VehicleMapper {

    public VehicleResponse toResponse(VehicleEntity entity) {
        return new VehicleResponse(
                entity.getId(),
                entity.getContact().getId(),
                entity.getLabel(),
                entity.getMake(),
                entity.getModel(),
                entity.getColor(),
                entity.getPlate(),
                entity.getSeats(),
                entity.getNotes(),
                entity.getCreatedAt()
        );
    }
}
