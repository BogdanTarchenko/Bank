package com.bank.user.dto.mapper;

import com.bank.user.dto.CreateUserRequest;
import com.bank.user.dto.UserResponse;
import com.bank.user.model.User;

public final class UserMapper {

    private UserMapper() {}

    public static User toEntity(CreateUserRequest request) {
        return User.builder()
                .email(request.email())
                .firstName(request.firstName())
                .lastName(request.lastName())
                .phone(request.phone())
                .roles(request.roles())
                .blocked(false)
                .build();
    }

    public static UserResponse toResponse(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getPhone(),
                user.isBlocked(),
                user.getRoles(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
