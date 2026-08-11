package com.pickup.common.geo.routing;

import com.pickup.common.geo.GeoPoint;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RouteEstimateServiceTest {

    private final HaversineTravelProvider haversine =
            new HaversineTravelProvider(travelProperties(10.0));

    @Test
    void estimateOrFallback_usesHaversineWhenGoogleDisabled() {
        RouteEstimateService service =
                new RouteEstimateService(haversine, Optional.<RouteEstimateProvider>empty());
        GeoPoint a = new GeoPoint(40.0, -74.0);
        GeoPoint b = new GeoPoint(40.01, -74.0);
        TravelMetrics metrics = service.estimateOrFallback(a, b);
        assertEquals(TravelEstimateSource.HAVERSINE, metrics.source());
        assertTrue(metrics.distanceMeters() > 0);
    }

    @Test
    void estimateOrFallback_prefersGoogleWhenAvailable() {
        RouteEstimateProvider google = (origin, destination) -> Optional.of(
                new TravelMetrics(5000, 600, TravelEstimateSource.GOOGLE_ROUTES));
        RouteEstimateService service = new RouteEstimateService(haversine, Optional.of(google));
        TravelMetrics metrics = service.estimateOrFallback(
                new GeoPoint(40.0, -74.0),
                new GeoPoint(40.1, -74.0));
        assertEquals(TravelEstimateSource.GOOGLE_ROUTES, metrics.source());
        assertEquals(5000, metrics.distanceMeters(), 0.001);
    }

    @Test
    void estimateOrFallback_fallsBackWhenGoogleEmpty() {
        RouteEstimateProvider google = (origin, destination) -> Optional.empty();
        RouteEstimateService service = new RouteEstimateService(haversine, Optional.of(google));
        TravelMetrics metrics = service.estimateOrFallback(
                new GeoPoint(40.0, -74.0),
                new GeoPoint(40.01, -74.0));
        assertEquals(TravelEstimateSource.HAVERSINE, metrics.source());
    }

    private static TravelProperties travelProperties(double speedMps) {
        TravelProperties properties = new TravelProperties();
        properties.setAssumedSpeedMps(speedMps);
        return properties;
    }
}
