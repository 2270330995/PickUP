package com.pickup.dev;

import com.pickup.common.api.ApiResponse;
import com.pickup.dev.dto.DevAccountInfo;
import com.pickup.dev.dto.DevSeedResponse;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/dev")
@ConditionalOnProperty(name = "pickup.dev.enabled", havingValue = "true")
public class DevSeedController {

    private final DevSeedService devSeedService;

    public DevSeedController(DevSeedService devSeedService) {
        this.devSeedService = devSeedService;
    }

    /** Create (or refresh) a demo event with organizer, drivers, passengers, and vehicles. */
    @PostMapping("/seed")
    public ApiResponse<DevSeedResponse> seed() {
        return ApiResponse.ok(devSeedService.seed());
    }

    /** List demo account emails and the shared password. */
    @GetMapping("/accounts")
    public ApiResponse<List<DevAccountInfo>> accounts() {
        return ApiResponse.ok(devSeedService.listAccounts());
    }
}
