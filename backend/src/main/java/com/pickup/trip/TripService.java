package com.pickup.trip;

import com.pickup.common.exception.ForbiddenException;
import com.pickup.common.exception.NotFoundException;
import com.pickup.event.EventEntity;
import com.pickup.trip.dto.TripResponse;
import com.pickup.tripstop.TripStopEntity;
import com.pickup.tripstop.TripStopRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class TripService {

    private final TripRepository tripRepository;
    private final TripStopRepository tripStopRepository;
    private final TripMapper tripMapper;

    public TripService(TripRepository tripRepository,
                       TripStopRepository tripStopRepository,
                       TripMapper tripMapper) {
        this.tripRepository = tripRepository;
        this.tripStopRepository = tripStopRepository;
        this.tripMapper = tripMapper;
    }

    @Transactional(readOnly = true)
    public List<TripResponse> listTripsForEvent(UUID eventId) {
        return tripRepository.findAllByEventIdOrderByCreatedAtAsc(eventId).stream()
                .map(tripMapper::toResponse)
                .toList();
    }

    /**
     * Single-trip read with authorization: caller must be the event organizer,
     * the trip's driver, or a participant referenced in one of the trip's stops.
     */
    @Transactional(readOnly = true)
    public TripResponse getTrip(UUID tripId, UUID viewerId) {
        TripEntity trip = loadOrThrow(tripId);
        assertCanView(trip, viewerId);
        return tripMapper.toResponse(trip);
    }

    /**
     * Trips visible to the caller — both trips they drive and trips containing
     * a stop for them as a passenger. Trips are deduplicated and returned in
     * driver-trip-creation-newest-first order, with passenger-only trips appended.
     */
    @Transactional(readOnly = true)
    public List<TripResponse> listMyTrips(UUID userId) {
        Map<UUID, TripEntity> byId = new LinkedHashMap<>();
        for (TripEntity trip : tripRepository.findAllByDriverIdOrderByCreatedAtDesc(userId)) {
            byId.putIfAbsent(trip.getId(), trip);
        }
        for (TripStopEntity stop : tripStopRepository.findAllByParticipantUserId(userId)) {
            TripEntity trip = stop.getTrip();
            byId.putIfAbsent(trip.getId(), trip);
        }
        return byId.values().stream()
                .sorted(Comparator.comparing(TripEntity::getCreatedAt).reversed())
                .map(tripMapper::toResponse)
                .toList();
    }

    public TripEntity loadOrThrow(UUID tripId) {
        return tripRepository.findById(tripId)
                .orElseThrow(() -> NotFoundException.of("Trip", tripId));
    }

    /**
     * Whether the given user is the event organizer, the trip's driver,
     * or appears in one of the trip's stops as a participant.
     */
    public boolean canView(TripEntity trip, UUID userId) {
        EventEntity event = trip.getEvent();
        if (event.getOrganizer().getId().equals(userId)) return true;
        if (trip.getDriver() != null && trip.getDriver().getId().equals(userId)) return true;
        return trip.getStops().stream()
                .anyMatch(s -> s.getParticipant().getUser() != null
                        && s.getParticipant().getUser().getId().equals(userId));
    }

    private void assertCanView(TripEntity trip, UUID userId) {
        if (!canView(trip, userId)) {
            throw new ForbiddenException("You are not allowed to view this trip");
        }
    }
}
