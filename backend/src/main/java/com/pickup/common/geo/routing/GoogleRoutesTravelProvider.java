package com.pickup.common.geo.routing;

import com.fasterxml.jackson.databind.JsonNode;
import com.pickup.common.geo.GeoPoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;
import java.util.Optional;

/**
 * Google Routes API computeRoutes integration (traffic-unaware for deterministic estimates).
 */
@Component
@ConditionalOnProperty(prefix = "pickup.google.routes", name = "enabled", havingValue = "true")
public class GoogleRoutesTravelProvider implements RouteEstimateProvider {

    private static final Logger log = LoggerFactory.getLogger(GoogleRoutesTravelProvider.class);

    private final GoogleRoutesProperties properties;
    private final RestClient restClient;

    public GoogleRoutesTravelProvider(GoogleRoutesProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .build();
    }

    @Override
    public Optional<TravelMetrics> estimate(GeoPoint origin, GeoPoint destination) {
        if (properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            return Optional.empty();
        }
        try {
            JsonNode response = restClient.post()
                    .uri("/directions/v2:computeRoutes")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("X-Goog-Api-Key", properties.getApiKey())
                    .header("X-Goog-FieldMask", "routes.distanceMeters,routes.duration")
                    .body(Map.of(
                            "origin", waypoint(origin),
                            "destination", waypoint(destination),
                            "travelMode", "DRIVE",
                            "routingPreference", "TRAFFIC_UNAWARE"))
                    .retrieve()
                    .body(JsonNode.class);
            if (response == null) {
                return Optional.empty();
            }
            JsonNode routes = response.get("routes");
            if (routes == null || !routes.isArray() || routes.isEmpty()) {
                return Optional.empty();
            }
            JsonNode route = routes.get(0);
            double distanceMeters = route.path("distanceMeters").asDouble(0);
            String durationText = route.path("duration").asText("");
            long durationSeconds = parseDurationSeconds(durationText);
            if (distanceMeters <= 0 || durationSeconds <= 0) {
                return Optional.empty();
            }
            return Optional.of(new TravelMetrics(
                    distanceMeters,
                    durationSeconds,
                    TravelEstimateSource.GOOGLE_ROUTES));
        } catch (RestClientException ex) {
            log.debug("Google Routes estimate failed: {}", ex.getMessage());
            return Optional.empty();
        }
    }

    private static Map<String, Object> waypoint(GeoPoint point) {
        return Map.of(
                "location", Map.of(
                        "latLng", Map.of(
                                "latitude", point.lat(),
                                "longitude", point.lng())));
    }

    static long parseDurationSeconds(String duration) {
        if (duration == null || duration.isBlank()) {
            return 0;
        }
        if (duration.endsWith("s")) {
            String numeric = duration.substring(0, duration.length() - 1);
            try {
                return Math.max(1L, Math.round(Double.parseDouble(numeric)));
            } catch (NumberFormatException ignored) {
                return 0;
            }
        }
        return 0;
    }
}
