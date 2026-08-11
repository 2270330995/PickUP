package com.pickup.common.geo.routing;

import com.pickup.common.geo.GeoPoint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * Resolves travel metrics between two points, preferring Google Routes when enabled
 * and falling back to Haversine estimates. Never throws to callers.
 */
@Service
public class RouteEstimateService {

    private final HaversineTravelProvider haversineTravelProvider;
    private final Optional<RouteEstimateProvider> googleRoutesProvider;

    @Autowired
    public RouteEstimateService(
            HaversineTravelProvider haversineTravelProvider,
            @Autowired(required = false) GoogleRoutesTravelProvider googleRoutesTravelProvider) {
        this(
                haversineTravelProvider,
                Optional.ofNullable(googleRoutesTravelProvider));
    }

    /** Package-visible for unit tests with a stub {@link RouteEstimateProvider}. */
    RouteEstimateService(
            HaversineTravelProvider haversineTravelProvider,
            Optional<RouteEstimateProvider> googleRoutesProvider) {
        this.haversineTravelProvider = haversineTravelProvider;
        this.googleRoutesProvider = googleRoutesProvider;
    }

    public TravelMetrics estimateOrFallback(GeoPoint origin, GeoPoint destination) {
        if (googleRoutesProvider.isPresent()) {
            Optional<TravelMetrics> google = googleRoutesProvider.get().estimate(origin, destination);
            if (google.isPresent()) {
                return google.get();
            }
        }
        return haversineTravelProvider.estimate(origin, destination).orElseThrow();
    }

    /**
     * Distance in meters for planning heuristics (route-aware when available).
     */
    public double distanceMeters(GeoPoint origin, GeoPoint destination) {
        return estimateOrFallback(origin, destination).distanceMeters();
    }

    public Optional<String> fetchRoutePolyline(List<GeoPoint> waypoints) {
        // Polyline enrichment deferred until a dedicated Routes response parser is needed.
        return Optional.empty();
    }
}
