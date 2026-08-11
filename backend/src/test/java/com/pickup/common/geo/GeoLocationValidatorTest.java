package com.pickup.common.geo;

import com.pickup.common.exception.BadRequestException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GeoLocationValidatorTest {

    @Test
    void isComplete_acceptsValidTriple() {
        assertTrue(GeoLocationValidator.isComplete("123 Main St", 40.7128, -74.0060));
    }

    @Test
    void isComplete_rejectsPartial() {
        assertFalse(GeoLocationValidator.isComplete(null, 40.0, -74.0));
        assertFalse(GeoLocationValidator.isComplete("  ", 40.0, -74.0));
        assertFalse(GeoLocationValidator.isComplete("Addr", null, -74.0));
        assertFalse(GeoLocationValidator.isComplete("Addr", 40.0, null));
    }

    @Test
    void isComplete_rejectsOutOfRangeCoords() {
        assertFalse(GeoLocationValidator.isComplete("Addr", 91.0, 0.0));
        assertFalse(GeoLocationValidator.isComplete("Addr", 0.0, 181.0));
    }

    @Test
    void requireComplete_throwsOnMissingAddress() {
        assertThrows(BadRequestException.class,
                () -> GeoLocationValidator.requireComplete(null, 40.0, -74.0, "Destination"));
    }

    @Test
    void requireCompleteOrAbsent_allowsAllAbsent() {
        assertDoesNotThrow(() -> GeoLocationValidator.requireCompleteOrAbsent(null, null, null, "Pickup"));
    }

    @Test
    void requireCompleteOrAbsent_rejectsPartial() {
        assertThrows(BadRequestException.class,
                () -> GeoLocationValidator.requireCompleteOrAbsent("Addr", null, null, "Pickup"));
    }
}
