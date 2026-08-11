package com.pickup.common.geo;

import com.pickup.common.exception.BadRequestException;
import com.pickup.trip.navigation.GoogleMapsNavigationUrlBuilder;

/**
 * Shared validation for address + coordinate location payloads used across events
 * and participant pickup / trip-start fields.
 */
public final class GeoLocationValidator {

    private GeoLocationValidator() {}

    public static boolean isValidCoordinate(double lat, double lng) {
        return GoogleMapsNavigationUrlBuilder.isValidCoordinate(lat, lng);
    }

    public static void validateCoordinateRange(double lat, double lng, String fieldLabel) {
        if (!isValidCoordinate(lat, lng)) {
            throw new BadRequestException(
                    fieldLabel + " coordinates are invalid (lat must be -90..90, lng must be -180..180)");
        }
    }

    public static boolean isComplete(String address, Double lat, Double lng) {
        return address != null
                && !address.isBlank()
                && lat != null
                && lng != null
                && isValidCoordinate(lat, lng);
    }

    public static void requireComplete(String address, Double lat, Double lng, String fieldLabel) {
        if (address == null || address.isBlank()) {
            throw new BadRequestException(fieldLabel + " address is required");
        }
        if (lat == null || lng == null) {
            throw new BadRequestException(fieldLabel + " latitude and longitude are required");
        }
        validateCoordinateRange(lat, lng, fieldLabel);
    }

    public static void requireCompleteOrAbsent(String address, Double lat, Double lng, String fieldLabel) {
        boolean hasAddress = address != null && !address.isBlank();
        boolean hasLat = lat != null;
        boolean hasLng = lng != null;
        if (!hasAddress && !hasLat && !hasLng) {
            return;
        }
        requireComplete(
                hasAddress ? address : null,
                hasLat ? lat : null,
                hasLng ? lng : null,
                fieldLabel);
    }
}
