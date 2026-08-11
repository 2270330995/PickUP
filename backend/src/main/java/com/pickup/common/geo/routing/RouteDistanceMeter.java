package com.pickup.common.geo.routing;

import com.pickup.common.geo.GeoPoint;

@FunctionalInterface
public interface RouteDistanceMeter {

    double distanceMeters(GeoPoint from, GeoPoint to);
}
