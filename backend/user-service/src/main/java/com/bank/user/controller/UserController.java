package com.bank.user.controller;

import com.bank.user.dto.CreateUserRequest;
import com.bank.user.dto.UpdateRolesRequest;
import com.bank.user.dto.UpdateUserRequest;
import com.bank.user.dto.UserResponse;
import com.bank.user.model.Role;
import com.bank.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/roles")
    public List<Role> getAvailableRoles() {
        return Arrays.asList(Role.values());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse createUser(@Valid @RequestBody CreateUserRequest request) {
        return userService.createUser(request);
    }

    @GetMapping("/{id}")
    public UserResponse getUser(@PathVariable Long id) {
        return userService.getUserById(id);
    }

    @GetMapping
    public List<UserResponse> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/by-email")
    public UserResponse getUserByEmail(@RequestParam String email) {
        return userService.getUserByEmail(email);
    }

    @PutMapping("/{id}")
    public UserResponse updateUser(@PathVariable Long id, @Valid @RequestBody UpdateUserRequest request) {
        return userService.updateUser(id, request);
    }

    @PatchMapping("/{id}/roles")
    public UserResponse updateUserRoles(@PathVariable Long id, @Valid @RequestBody UpdateRolesRequest request) {
        return userService.updateUserRoles(id, request.roles());
    }

    @PatchMapping("/{id}/block")
    public UserResponse blockUser(@PathVariable Long id) {
        return userService.blockUser(id);
    }

    @PatchMapping("/{id}/unblock")
    public UserResponse unblockUser(@PathVariable Long id) {
        return userService.unblockUser(id);
    }
}
