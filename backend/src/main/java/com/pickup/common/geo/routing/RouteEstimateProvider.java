package com.pickup.common.geo.routing;

import com.pickup.common.geo.GeoPoint;

import java.util.Optional;

public interface RouteEstimateProvider {

    Optional<TravelMetrics> estimate(GeoPoint origin, GeoPoint destination);
}
