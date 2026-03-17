package com.bank.user.service;

import com.bank.user.dto.CreateUserRequest;
import com.bank.user.dto.UpdateUserRequest;
import com.bank.user.dto.UserResponse;
import com.bank.user.dto.mapper.UserMapper;
import com.bank.user.exception.EmailAlreadyExistsException;
import com.bank.user.exception.UserNotFoundException;
import com.bank.user.model.User;
import com.bank.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new EmailAlreadyExistsException(request.email());
        }
        User user = UserMapper.toEntity(request);
        return UserMapper.toResponse(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public UserResponse getUserById(Long id) {
        return UserMapper.toResponse(findById(id));
    }

    @Transactional(readOnly = true)
    public UserResponse getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException(-1L));
        return UserMapper.toResponse(user);
    }

    @Transactional(readOnly = true)
    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream()
                .map(UserMapper::toResponse)
                .toList();
    }

    @Transactional
    public UserResponse updateUser(Long id, UpdateUserRequest request) {
        User user = findById(id);

        if (request.email() != null && !request.email().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.email())) {
                throw new EmailAlreadyExistsException(request.email());
            }
            user.setEmail(request.email());
        }
        if (request.firstName() != null) {
            user.setFirstName(request.firstName());
        }
        if (request.lastName() != null) {
            user.setLastName(request.lastName());
        }
        if (request.phone() != null) {
            user.setPhone(request.phone());
        }

        return UserMapper.toResponse(userRepository.save(user));
    }

    @Transactional
    public UserResponse blockUser(Long id) {
        User user = findById(id);
        user.setBlocked(true);
        return UserMapper.toResponse(userRepository.save(user));
    }

    @Transactional
    public UserResponse unblockUser(Long id) {
        User user = findById(id);
        user.setBlocked(false);
        return UserMapper.toResponse(userRepository.save(user));
    }

    private User findById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
    }
}
