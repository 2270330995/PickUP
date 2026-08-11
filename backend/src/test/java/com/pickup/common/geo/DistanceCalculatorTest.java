package com.pickup.common.geo;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DistanceCalculatorTest {

    @Test
    void samePoint_returnsZero() {
        assertEquals(0.0, DistanceCalculator.distanceMeters(40.7128, -74.0060, 40.7128, -74.0060));
    }

    @Test
    void nycToLa_isApproximately3940Km() {
        double meters = DistanceCalculator.distanceMeters(40.7128, -74.0060, 34.0522, -118.2437);
        assertTrue(meters > 3_900_000 && meters < 3_980_000,
                "Expected ~3940 km, got " + meters + " m");
    }

    @Test
    void geoPointOverload_matchesCoordinateOverload() {
        GeoPoint nyc = new GeoPoint(40.7128, -74.0060);
        GeoPoint la = new GeoPoint(34.0522, -118.2437);
        assertEquals(
                DistanceCalculator.distanceMeters(nyc.lat(), nyc.lng(), la.lat(), la.lng()),
                DistanceCalculator.distanceMeters(nyc, la));
    }
}
