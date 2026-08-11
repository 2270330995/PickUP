package com.pickup.event.assignment.dto;

import com.pickup.trip.dto.TripResponse;

import java.util.List;
import java.util.UUID;

/**
 * Snapshot of the manual-assignment state for one event.
 * Returned by both {@code POST /events/{id}/assignments} (after a save) and
 * {@code GET /events/{id}/trips} so the organizer UI can render trips and the
 * pool of remaining unassigned passengers in a single round-trip.
 */
public record AssignmentPlanResponse(
        UUID eventId,
        List<TripResponse> trips,
        List<UUID> unassignedConfirmedPassengerIds
) {}
