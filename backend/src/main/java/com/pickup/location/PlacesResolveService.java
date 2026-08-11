package com.pickup.location;

import com.fasterxml.jackson.databind.JsonNode;
import com.pickup.common.exception.BadRequestException;
import com.pickup.location.dto.ResolvePlaceRequest;
import com.pickup.location.dto.ResolvedPlaceResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;

/**
 * Server-side Google Places resolution. Used by the Flutter web client because
 * browser CORS only allows autocomplete (not Place Details field-mask headers).
 */
@Service
public class PlacesResolveService {

    private static final String BASE_URL = "https://places.googleapis.com/v1";

    private final PlacesProperties properties;
    private final RestClient restClient;

    public PlacesResolveService(PlacesProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder().baseUrl(BASE_URL).build();
    }

    public ResolvedPlaceResponse resolve(ResolvePlaceRequest request) {
        if (!properties.isConfigured()) {
            throw new BadRequestException(
                    "Google Places is not configured on the server (set GOOGLE_PLACES_API_KEY)");
        }
        if (request.placeId() != null && !request.placeId().isBlank()) {
            try {
                return fetchPlaceDetails(request.placeId(), request.sessionToken());
            } catch (RestClientException ignored) {
                // Fall through to text search using the autocomplete label.
            }
        }
        return searchText(request.query(), request.sessionToken());
    }

    private ResolvedPlaceResponse fetchPlaceDetails(String placeId, String sessionToken) {
        String normalizedId = normalizePlaceId(placeId);
        var spec = restClient.get()
                .uri("/places/{placeId}", normalizedId)
                .header("X-Goog-Api-Key", properties.getApiKey())
                .header("X-Goog-FieldMask", "formattedAddress,location");
        if (sessionToken != null && !sessionToken.isBlank()) {
            spec = spec.header("X-Goog-Session-Token", sessionToken);
        }
        JsonNode body = spec.retrieve().body(JsonNode.class);
        return parsePlace(body);
    }

    private ResolvedPlaceResponse searchText(String query, String sessionToken) {
        var spec = restClient.post()
                .uri("/places:searchText")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Goog-Api-Key", properties.getApiKey())
                .header("X-Goog-FieldMask", "places.formattedAddress,places.location");
        if (sessionToken != null && !sessionToken.isBlank()) {
            spec = spec.header("X-Goog-Session-Token", sessionToken);
        }
        JsonNode body = spec.body(Map.of(
                        "textQuery", query,
                        "maxResultCount", 1))
                .retrieve()
                .body(JsonNode.class);
        JsonNode places = body != null ? body.get("places") : null;
        if (places == null || !places.isArray() || places.isEmpty()) {
            throw new BadRequestException("Could not resolve selected address");
        }
        return parsePlace(places.get(0));
    }

    private static ResolvedPlaceResponse parsePlace(JsonNode node) {
        if (node == null) {
            throw new BadRequestException("Could not resolve selected address");
        }
        String address = node.path("formattedAddress").asText(null);
        double lat = node.path("location").path("latitude").asDouble(Double.NaN);
        double lng = node.path("location").path("longitude").asDouble(Double.NaN);
        if (address == null || address.isBlank() || Double.isNaN(lat) || Double.isNaN(lng)) {
            throw new BadRequestException("Could not resolve selected address");
        }
        return new ResolvedPlaceResponse(address, lat, lng);
    }

    private static String normalizePlaceId(String raw) {
        return raw.startsWith("places/") ? raw.substring("places/".length()) : raw;
    }
}
