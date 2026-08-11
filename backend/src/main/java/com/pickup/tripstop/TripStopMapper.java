package com.pickup.tripstop;

import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.ParticipantDisplayResolver;
import com.pickup.trip.dto.TripResponse.TripStopSummary;
import com.pickup.user.UserEntity;
import org.springframework.stereotype.Component;

@Component
public class TripStopMapper {

    public TripStopSummary toSummary(TripStopEntity entity) {
        EventParticipantEntity participant = entity.getParticipant();
        UserEntity user = participant.getUser();
        return new TripStopSummary(
                entity.getId(),
                entity.getSequence(),
                participant.getId(),
                user == null ? null : user.getId(),
                ParticipantDisplayResolver.displayName(participant),
                entity.getAddress(),
                entity.getMeetingPointName(),
                entity.getLat(),
                entity.getLng(),
                entity.getStatus(),
                entity.getEtaMinutes(),
                entity.getActualArrivalTime(),
                entity.getActualDepartureTime()
        );
    }
}
