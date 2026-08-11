package com.pickup.trip.navigation;

import org.springframework.stereotype.Component;

/**
 * Builds cross-platform Google Maps turn-by-turn deep links from stored coordinates.
 * No external Maps API calls — HTTPS URLs open the native app on mobile when available.
 */
@Component
public class GoogleMapsNavigationUrlBuilder {

    private static final String DIRECTIONS_TEMPLATE =
            "https://www.google.com/maps/dir/?api=1&destination=%f,%f&travelmode=driving";

    /**
     * @return a Google Maps driving-directions URL, or {@code null} when coordinates
     *         are not finite or fall outside valid latitude/longitude ranges.
     */
    public String buildDrivingUrl(double lat, double lng) {
        if (!isValidCoordinate(lat, lng)) {
            return null;
        }
        return DIRECTIONS_TEMPLATE.formatted(lat, lng);
    }

    /**
     * Accepts any finite coordinate pair within standard WGS-84 bounds.
     * Zero is valid (e.g. Gulf of Guinea); only non-finite or out-of-range values fail.
     */
    public static boolean isValidCoordinate(double lat, double lng) {
        return Double.isFinite(lat)
                && Double.isFinite(lng)
                && lat >= -90.0
                && lat <= 90.0
                && lng >= -180.0
                && lng <= 180.0;
    }
}
