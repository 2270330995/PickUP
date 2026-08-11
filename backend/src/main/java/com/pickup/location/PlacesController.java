package com.pickup.location;

import com.pickup.common.api.ApiResponse;
import com.pickup.location.dto.ResolvePlaceRequest;
import com.pickup.location.dto.ResolvedPlaceResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/places")
public class PlacesController {

    private final PlacesResolveService placesResolveService;

    public PlacesController(PlacesResolveService placesResolveService) {
        this.placesResolveService = placesResolveService;
    }

    /** Resolves an autocomplete selection to a formatted address + coordinates. */
    @PostMapping("/resolve")
    public ApiResponse<ResolvedPlaceResponse> resolve(@Valid @RequestBody ResolvePlaceRequest request) {
        return ApiResponse.ok(placesResolveService.resolve(request));
    }
}
