package com.pickup.trip.planning;

import com.pickup.common.geo.GeoPoint;
import com.pickup.common.geo.routing.RouteEstimateService;
import com.pickup.common.geo.routing.TravelMetrics;
import com.pickup.event.EventEntity;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.trip.TripEntity;
import com.pickup.tripstop.TripStopEntity;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Populates static planning ETAs on newly created trips after assignment.
 */
@Service
public class TripRouteEnrichmentService {

    private final RouteEstimateService routeEstimateService;
    private final EventParticipantRepository participantRepository;

    public TripRouteEnrichmentService(
            RouteEstimateService routeEstimateService,
            EventParticipantRepository participantRepository) {
        this.routeEstimateService = routeEstimateService;
        this.participantRepository = participantRepository;
    }

    /**
     * Sets cumulative {@code etaMinutes} from route origin to each stop. Does not mutate stop order.
     */
    public void enrichTrip(TripEntity trip, EventEntity event) {
        List<TripStopEntity> stops = trip.getStops().stream()
                .sorted(Comparator.comparingInt(TripStopEntity::getSequence))
                .toList();
        if (stops.isEmpty()) {
            return;
        }

        GeoPoint current = resolveRouteOrigin(trip, event).orElseGet(() ->
                new GeoPoint(stops.getFirst().getLat(), stops.getFirst().getLng()));

        long cumulativeSeconds = 0L;
        for (TripStopEntity stop : stops) {
            GeoPoint stopPoint = new GeoPoint(stop.getLat(), stop.getLng());
            TravelMetrics leg = routeEstimateService.estimateOrFallback(current, stopPoint);
            cumulativeSeconds += leg.durationSeconds();
            stop.setEtaMinutes(toEtaMinutes(cumulativeSeconds));
            current = stopPoint;
        }

        routeEstimateService.fetchRoutePolyline(buildWaypoints(stops, event))
                .ifPresent(trip::setEncodedPolyline);
    }

    private Optional<GeoPoint> resolveRouteOrigin(TripEntity trip, EventEntity event) {
        EventParticipantEntity driverParticipant = trip.getDriverParticipant();
        if (driverParticipant != null) {
            return GeoPoint.tripStartFromDriver(driverParticipant);
        }
        if (trip.getDriver() == null || trip.getDriver().getId() == null) {
            return Optional.empty();
        }
        return participantRepository
                .findByEventIdAndUserId(event.getId(), trip.getDriver().getId())
                .flatMap(GeoPoint::tripStartFromDriver);
    }

    private static List<GeoPoint> buildWaypoints(List<TripStopEntity> stops, EventEntity event) {
        var points = new ArrayList<GeoPoint>(stops.size() + 1);
        for (TripStopEntity stop : stops) {
            points.add(new GeoPoint(stop.getLat(), stop.getLng()));
        }
        points.add(new GeoPoint(event.getDestinationLat(), event.getDestinationLng()));
        return points;
    }

    static int toEtaMinutes(long cumulativeSeconds) {
        return (int) Math.max(1L, Math.ceil(cumulativeSeconds / 60.0));
    }
}
