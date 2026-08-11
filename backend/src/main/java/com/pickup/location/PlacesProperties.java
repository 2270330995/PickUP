package com.pickup.location;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pickup.google.places")
public class PlacesProperties {

    private String apiKey = "";

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }
}
