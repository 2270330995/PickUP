package com.pickup.dev;

import com.pickup.dev.dto.DevSeedResponse;
import com.pickup.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "pickup.dev.auto-seed", havingValue = "true")
public class DevAutoSeedRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevAutoSeedRunner.class);

    private final DevSeedService devSeedService;
    private final UserRepository userRepository;

    public DevAutoSeedRunner(DevSeedService devSeedService, UserRepository userRepository) {
        this.devSeedService = devSeedService;
        this.userRepository = userRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.count() > 0) {
            return;
        }
        DevSeedResponse response = devSeedService.seed();
        log.info("Dev auto-seed complete: event '{}' ({}). Log in with any *@test.com account, password '{}'.",
                response.eventTitle(),
                response.eventId(),
                response.accounts().getFirst().password());
    }
}
