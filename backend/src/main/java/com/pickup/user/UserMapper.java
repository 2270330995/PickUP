package com.pickup.user;

import com.pickup.user.dto.UserResponse;
import org.springframework.stereotype.Component;

import java.util.EnumSet;

@Component
public class UserMapper {

    public UserResponse toResponse(UserEntity entity) {
        return new UserResponse(
                entity.getId(),
                entity.getEmail(),
                entity.getFullName(),
                entity.getPhone(),
                EnumSet.copyOf(entity.getSystemRoles()),
                entity.getCreatedAt()
        );
    }
}
