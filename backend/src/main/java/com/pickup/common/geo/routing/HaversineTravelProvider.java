package com.pickup.common.geo.routing;

import com.pickup.common.geo.DistanceCalculator;
import com.pickup.common.geo.GeoPoint;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * Fallback travel estimates from straight-line distance and an assumed urban driving speed.
 */
@Component
public class HaversineTravelProvider implements RouteEstimateProvider {

    private final TravelProperties properties;

    public HaversineTravelProvider(TravelProperties properties) {
        this.properties = properties;
    }

    @Override
    public Optional<TravelMetrics> estimate(GeoPoint origin, GeoPoint destination) {
        double distanceMeters = DistanceCalculator.distanceMeters(origin, destination);
        long durationSeconds = Math.max(
                1L,
                Math.round(distanceMeters / properties.getAssumedSpeedMps()));
        return Optional.of(new TravelMetrics(
                distanceMeters,
                durationSeconds,
                TravelEstimateSource.HAVERSINE));
    }
}
