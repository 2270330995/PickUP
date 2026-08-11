package com.pickup;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

import com.pickup.common.geo.routing.GoogleRoutesProperties;
import com.pickup.common.geo.routing.TravelProperties;
import com.pickup.location.PlacesProperties;

@SpringBootApplication
@EnableJpaAuditing
@EnableConfigurationProperties({TravelProperties.class, GoogleRoutesProperties.class, PlacesProperties.class})
public class PickUpApplication {

    public static void main(String[] args) {
        SpringApplication.run(PickUpApplication.class, args);
    }
}
