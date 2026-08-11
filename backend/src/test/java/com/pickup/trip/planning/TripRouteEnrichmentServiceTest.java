package com.pickup.trip.planning;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class TripRouteEnrichmentServiceTest {

    @Test
    void toEtaMinutes_roundsUpToWholeMinutes() {
        assertEquals(1, TripRouteEnrichmentService.toEtaMinutes(1));
        assertEquals(1, TripRouteEnrichmentService.toEtaMinutes(59));
        assertEquals(1, TripRouteEnrichmentService.toEtaMinutes(60));
        assertEquals(2, TripRouteEnrichmentService.toEtaMinutes(61));
    }
}
