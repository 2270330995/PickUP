package com.pickup.participant;

import com.pickup.common.api.ApiResponse;
import com.pickup.participant.dto.EventParticipantResponse;
import com.pickup.participant.dto.JoinEventRequest;
import com.pickup.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
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

    /** Organizer-only: hard delete participant row. */
    @DeleteMapping("/{participantId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable UUID eventId, @PathVariable UUID participantId) {
        participantService.remove(CurrentUser.require().getId(), eventId, participantId);
    }
}
