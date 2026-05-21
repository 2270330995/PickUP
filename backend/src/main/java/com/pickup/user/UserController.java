package com.pickup.user;

import com.pickup.common.api.ApiResponse;
import com.pickup.common.api.NotImplemented;
import com.pickup.security.CurrentUser;
import com.pickup.user.dto.UpdateUserRequest;
import com.pickup.user.dto.UserResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ApiResponse<UserResponse> getMe() {
        return ApiResponse.ok(userService.getCurrentUser(CurrentUser.require().getId()));
    }

    @PatchMapping("/me")
    public ApiResponse<UserResponse> updateMe(@Valid @RequestBody UpdateUserRequest request) {
        return ApiResponse.ok(userService.updateCurrentUser(CurrentUser.require().getId(), request));
    }

    @PostMapping("/me/fcm-token")
    public ApiResponse<Void> setFcmToken() {
        return NotImplemented.phase1("POST /api/v1/users/me/fcm-token");
    }
}
