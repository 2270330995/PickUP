package com.pickup.trip.navigation;

import com.pickup.common.enums.NavigationTargetType;
import com.pickup.common.geo.GeoPoint;
import com.pickup.participant.ParticipantDisplayResolver;
import com.pickup.trip.TripEntity;
import com.pickup.tripstop.TripStopEntity;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;

/**
 * Derives the current external-navigation target for a trip from execution state
 * and stored coordinates. Labels are short and stable; addresses are exposed
 * separately on trip/stop DTO fields for UI display.
 */
@Component
public class TripNavigationResolver {

    private final GoogleMapsNavigationUrlBuilder urlBuilder;

    public TripNavigationResolver(GoogleMapsNavigationUrlBuilder urlBuilder) {
        this.urlBuilder = urlBuilder;
    }

    /**
     * The whole planned route in one Google Maps link — every stop in sequence
     * order, ending at the destination — as opposed to {@link #resolve} which only
     * ever points at the single current/next leg based on live execution state.
     * Meant to be shared with a driver (including a Contact-backed one with no app
     * login) ahead of time, not just opened in-app once the trip has started.
     */
    public String resolveFullRouteUrl(TripEntity trip) {
        List<GeoPoint> waypoints = trip.getStops().stream()
                .sorted(Comparator.comparingInt(TripStopEntity::getSequence))
                .map(stop -> new GeoPoint(stop.getLat(), stop.getLng()))
                .toList();
        GeoPoint destination = new GeoPoint(trip.getFinalDestinationLat(), trip.getFinalDestinationLng());
        return urlBuilder.buildMultiStopDrivingUrl(waypoints, destination);
    }

    public NavigationInfo resolve(TripEntity trip) {
        return switch (trip.getStatus()) {
            case IN_PROGRESS -> resolveCurrentStop(trip.getCurrentStop());
            case ALL_PASSENGERS_PICKED -> resolveFinalDestination(trip);
            default -> NavigationInfo.none();
        };
    }

    private NavigationInfo resolveCurrentStop(TripStopEntity stop) {
        if (stop == null) {
            return NavigationInfo.none();
        }
        String url = urlBuilder.buildDrivingUrl(stop.getLat(), stop.getLng());
        if (url == null) {
            return NavigationInfo.none();
        }
        String label = "Pickup: " + ParticipantDisplayResolver.displayName(stop.getParticipant());
        return new NavigationInfo(NavigationTargetType.CURRENT_STOP, label, url);
    }

    private NavigationInfo resolveFinalDestination(TripEntity trip) {
        String url = urlBuilder.buildDrivingUrl(
                trip.getFinalDestinationLat(), trip.getFinalDestinationLng());
        if (url == null) {
            return NavigationInfo.none();
        }
        return new NavigationInfo(
                NavigationTargetType.FINAL_DESTINATION,
                "Final destination",
                url);
    }

    public record NavigationInfo(
            NavigationTargetType targetType,
            String label,
            String url
    ) {
        public static NavigationInfo none() {
            return new NavigationInfo(NavigationTargetType.NONE, null, null);
        }
    }
}
