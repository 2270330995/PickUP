package com.pickup.trip.navigation;

import com.pickup.common.geo.GeoPoint;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Builds cross-platform Google Maps turn-by-turn deep links from stored coordinates.
 * No external Maps API calls — HTTPS URLs open the native app on mobile when available.
 */
@Component
public class GoogleMapsNavigationUrlBuilder {

    private static final String DIRECTIONS_TEMPLATE =
            "https://www.google.com/maps/dir/?api=1&destination=%f,%f&travelmode=driving&dir_action=navigate";

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
     * Builds a single driving-directions URL covering every waypoint in order before
     * the destination — the whole planned route in one link, meant to be handed to a
     * driver (who may have no app login of their own) before they've started driving,
     * not just the single current/next leg.
     *
     * <p>Deliberately omits an "origin" so Google Maps starts from wherever the device
     * opening the link currently is, since this is generated ahead of the driver
     * actually being anywhere in particular. Per Google's Maps URLs docs, omitting the
     * origin combined with {@code dir_action=navigate} is what makes the app land
     * directly in turn-by-turn navigation instead of an editable trip-planner screen
     * the driver would otherwise have to manually confirm through.
     *
     * <p>Google's docs cap waypoints at 3 when the link opens in a mobile browser
     * (e.g. tapped inside a messaging app's in-app browser) vs. 9 when it opens
     * directly in the native app or on desktop. A route with more stops than that
     * still gets a URL here (waypoints are never silently dropped, since that would
     * mean a driver misses a real pickup), but Maps itself may reject or truncate it
     * client-side depending on how the link was opened.
     *
     * @return a Google Maps driving-directions URL, or {@code null} when the
     *         destination's coordinates are invalid. Invalid individual waypoints are
     *         skipped rather than failing the whole link.
     */
    public String buildMultiStopDrivingUrl(List<GeoPoint> waypoints, GeoPoint destination) {
        if (destination == null || !isValidCoordinate(destination.lat(), destination.lng())) {
            return null;
        }
        StringBuilder url = new StringBuilder("https://www.google.com/maps/dir/?api=1&destination=")
                .append(formatCoord(destination))
                .append("&travelmode=driving");

        List<String> validWaypoints = waypoints.stream()
                .filter(p -> p != null && isValidCoordinate(p.lat(), p.lng()))
                .map(this::formatCoord)
                .collect(Collectors.toList());
        if (!validWaypoints.isEmpty()) {
            url.append("&waypoints=").append(String.join("|", validWaypoints));
        }
        url.append("&dir_action=navigate");
        return url.toString();
    }

    private String formatCoord(GeoPoint point) {
        return "%f,%f".formatted(point.lat(), point.lng());
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
