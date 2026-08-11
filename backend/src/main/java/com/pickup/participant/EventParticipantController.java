package com.pickup.participant;

import com.pickup.common.api.ApiResponse;
import com.pickup.participant.dto.AddContactParticipantRequest;
import com.pickup.participant.dto.AddContactsFromRosterRequest;
import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.JoinEventRequest;
import com.pickup.participant.dto.OrganizerUpdateParticipantRequest;
import com.pickup.participant.dto.UpdateParticipantPickupRequest;
import com.pickup.participant.dto.UpdateParticipantVehicleRequest;
import com.pickup.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events/{eventId}/participants")
public class EventParticipantController {

    private final EventParticipantService participantService;

    public EventParticipantController(EventParticipantService participantService) {
        this.participantService = participantService;
    }

    /** Self-join (any authenticated user). Creates a REQUESTED row. */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<EventParticipantResponse> selfJoin(@PathVariable UUID eventId,
                                                          @Valid @RequestBody JoinEventRequest request) {
        return ApiResponse.ok(participantService.selfJoin(CurrentUser.require().getId(), eventId, request));
    }

    @GetMapping
    public ApiResponse<List<EventParticipantResponse>> list(@PathVariable UUID eventId) {
        CurrentUser.require();
        return ApiResponse.ok(participantService.listForEvent(eventId));
    }

    /** Organizer-only: add a single Contact from the People roster as a READY participant. */
    @PostMapping("/from-contact")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<EventParticipantResponse> addFromContact(@PathVariable UUID eventId,
                                                                @Valid @RequestBody AddContactParticipantRequest request) {
        return ApiResponse.ok(
                participantService.addFromContact(CurrentUser.require().getId(), eventId, request));
    }

    /** Organizer-only: add multiple Contacts atomically (all-or-nothing). */
    @PostMapping("/from-contacts")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<List<EventParticipantResponse>> addFromContacts(
            @PathVariable UUID eventId,
            @Valid @RequestBody AddContactsFromRosterRequest request) {
        return ApiResponse.ok(
                participantService.addFromContacts(CurrentUser.require().getId(), eventId, request));
    }

    /** Organizer-only: edit a participant's per-event role and pickup location. */
    @PatchMapping("/{participantId}")
    public ApiResponse<EventParticipantResponse> organizerUpdate(
            @PathVariable UUID eventId,
            @PathVariable UUID participantId,
            @Valid @RequestBody OrganizerUpdateParticipantRequest request) {
        return ApiResponse.ok(participantService.organizerUpdate(
                CurrentUser.require().getId(), eventId, participantId, request));
    }

    /** Organizer-only: REQUESTED -> APPROVED. */
    @PostMapping("/{participantId}/approve")
    public ApiResponse<EventParticipantResponse> approve(@PathVariable UUID eventId,
                                                         @PathVariable UUID participantId) {
        return ApiResponse.ok(participantService.approve(CurrentUser.require().getId(), eventId, participantId));
    }

    /** Organizer-only: REQUESTED -> REJECTED. */
    @PostMapping("/{participantId}/reject")
    public ApiResponse<EventParticipantResponse> reject(@PathVariable UUID eventId,
                                                        @PathVariable UUID participantId) {
        return ApiResponse.ok(participantService.reject(CurrentUser.require().getId(), eventId, participantId));
    }

    /** Participant-only: APPROVED -> CONFIRMED. */
    @PostMapping("/{participantId}/confirm")
    public ApiResponse<EventParticipantResponse> confirm(@PathVariable UUID eventId,
                                                         @PathVariable UUID participantId) {
        return ApiResponse.ok(participantService.confirm(CurrentUser.require().getId(), eventId, participantId));
    }

    /** Participant-only: REQUESTED/APPROVED/CONFIRMED -> CANCELLED. */
    @PostMapping("/{participantId}/cancel")
    public ApiResponse<EventParticipantResponse> cancel(@PathVariable UUID eventId,
                                                        @PathVariable UUID participantId) {
        return ApiResponse.ok(participantService.cancel(CurrentUser.require().getId(), eventId, participantId));
    }

    /** Participant-only: CANCELLED -> REQUESTED (self-cancelled rejoin). */
    @PostMapping("/{participantId}/rejoin")
    public ApiResponse<EventParticipantResponse> rejoin(@PathVariable UUID eventId,
                                                        @PathVariable UUID participantId) {
        return ApiResponse.ok(participantService.rejoin(CurrentUser.require().getId(), eventId, participantId));
    }

    /** Passenger sets or updates their pickup location for this event. */
    @PatchMapping("/{participantId}/pickup")
    public ApiResponse<EventParticipantResponse> setPickup(@PathVariable UUID eventId,
                                                           @PathVariable UUID participantId,
                                                           @Valid @RequestBody UpdateParticipantPickupRequest request) {
        return ApiResponse.ok(participantService.setPickup(
                CurrentUser.require().getId(), eventId, participantId, request));
    }

    /** Driver sets or updates their trip start location for this event. */
    @PatchMapping("/{participantId}/trip-start")
    public ApiResponse<EventParticipantResponse> setTripStart(@PathVariable UUID eventId,
                                                              @PathVariable UUID participantId,
                                                              @Valid @RequestBody UpdateParticipantPickupRequest request) {
        return ApiResponse.ok(participantService.setTripStart(
                CurrentUser.require().getId(), eventId, participantId, request));
    }

    /**
     * Driver picks which of their own vehicles will be used for this event. Pass a
     * {@code null} {@code vehicleId} in the body to clear the selection (allowed only
     * before the participant is ASSIGNED to a trip).
     */
    @PatchMapping("/{participantId}/vehicle")
    public ApiResponse<EventParticipantResponse> setVehicle(@PathVariable UUID eventId,
                                                            @PathVariable UUID participantId,
                                                            @Valid @RequestBody UpdateParticipantVehicleRequest request) {
        return ApiResponse.ok(participantService.setVehicle(
                CurrentUser.require().getId(), eventId, participantId, request));
    }

    /** Organizer-only: soft-remove (sets status CANCELLED; row is preserved for history). */
    @DeleteMapping("/{participantId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable UUID eventId, @PathVariable UUID participantId) {
        participantService.remove(CurrentUser.require().getId(), eventId, participantId);
    }
}
