package com.pickup.common.geo;

/**
 * Deterministic geographic distance on the WGS-84 spheroid. No external APIs.
 */
public final class DistanceCalculator {

    public static final double EARTH_RADIUS_METERS = 6_371_000.0;

    private DistanceCalculator() {}

    /**
     * Haversine great-circle distance between two lat/lng points in meters.
     */
    public static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
        double lat1Rad = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);
        double deltaLat = Math.toRadians(lat2 - lat1);
        double deltaLng = Math.toRadians(lng2 - lng1);

        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(lat1Rad) * Math.cos(lat2Rad)
                * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_METERS * c;
    }

    public static double distanceMeters(GeoPoint from, GeoPoint to) {
        return distanceMeters(from.lat(), from.lng(), to.lat(), to.lng());
    }
}
