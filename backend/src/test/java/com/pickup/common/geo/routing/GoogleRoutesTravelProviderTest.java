package com.pickup.common.geo.routing;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GoogleRoutesTravelProviderTest {

    @Test
    void parseDurationSeconds_parsesProtoDuration() {
        assertEquals(123L, GoogleRoutesTravelProvider.parseDurationSeconds("123s"));
        assertEquals(1L, GoogleRoutesTravelProvider.parseDurationSeconds("0.5s"));
        assertEquals(0L, GoogleRoutesTravelProvider.parseDurationSeconds(""));
    }
}
