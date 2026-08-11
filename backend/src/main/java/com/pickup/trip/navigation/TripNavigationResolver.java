package com.pickup.trip.navigation;

import com.pickup.common.enums.NavigationTargetType;
import com.pickup.participant.ParticipantDisplayResolver;
import com.pickup.trip.TripEntity;
import com.pickup.tripstop.TripStopEntity;
import org.springframework.stereotype.Component;

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
