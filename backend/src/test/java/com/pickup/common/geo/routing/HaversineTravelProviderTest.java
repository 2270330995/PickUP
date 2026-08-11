package com.pickup.common.geo.routing;

import com.pickup.common.geo.GeoPoint;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class HaversineTravelProviderTest {

    private final HaversineTravelProvider provider =
            new HaversineTravelProvider(travelProperties(11.0));

    @Test
    void estimate_samePoint_isNearZeroDuration() {
        GeoPoint point = new GeoPoint(40.7128, -74.0060);
        TravelMetrics metrics = provider.estimate(point, point).orElseThrow();
        assertEquals(0.0, metrics.distanceMeters(), 0.001);
        assertEquals(1L, metrics.durationSeconds());
        assertEquals(TravelEstimateSource.HAVERSINE, metrics.source());
    }

    @Test
    void estimate_knownDistance_usesAssumedSpeed() {
        GeoPoint nyc = new GeoPoint(40.7128, -74.0060);
        GeoPoint nearby = new GeoPoint(40.7228, -74.0060);
        TravelMetrics metrics = provider.estimate(nyc, nearby).orElseThrow();
        assertTrue(metrics.distanceMeters() > 1000);
        assertTrue(metrics.durationSeconds() >= 1);
    }

    private static TravelProperties travelProperties(double speedMps) {
        TravelProperties properties = new TravelProperties();
        properties.setAssumedSpeedMps(speedMps);
        return properties;
    }
}
