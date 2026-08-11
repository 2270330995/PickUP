package com.pickup.common.geo.routing;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pickup.google.travel")
public class TravelProperties {

    /** Assumed driving speed for Haversine duration fallback (m/s). */
    private double assumedSpeedMps = 11.0;

    public double getAssumedSpeedMps() {
        return assumedSpeedMps;
    }

    public void setAssumedSpeedMps(double assumedSpeedMps) {
        this.assumedSpeedMps = assumedSpeedMps;
    }
}
