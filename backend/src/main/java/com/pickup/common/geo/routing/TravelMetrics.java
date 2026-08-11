package com.pickup.common.geo.routing;

/**
 * Estimated travel between two geographic points.
 */
public record TravelMetrics(
        double distanceMeters,
        long durationSeconds,
        TravelEstimateSource source
) {}
