package com.pickup.dev;

import com.pickup.common.enums.EventStatus;
import com.pickup.common.enums.ParticipantRole;
import com.pickup.common.enums.ParticipantStatus;
import com.pickup.common.enums.SystemRole;
import com.pickup.contact.ContactEntity;
import com.pickup.contact.ContactRepository;
import com.pickup.dev.dto.DevAccountInfo;
import com.pickup.dev.dto.DevSeedResponse;
import com.pickup.event.EventEntity;
import com.pickup.event.EventRepository;
import com.pickup.participant.EventParticipantEntity;
import com.pickup.participant.EventParticipantRepository;
import com.pickup.user.UserEntity;
import com.pickup.user.UserRepository;
import com.pickup.vehicle.VehicleEntity;
import com.pickup.vehicle.VehicleRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.List;

/**
 * Organizer-first dev seed: a single organizer account, a reusable Contact
 * roster (drivers with vehicles, passengers with pickup defaults), and a demo
 * event owned by that organizer with every contact already added as a READY
 * participant (Phase 4D-2), ready for immediate assignment testing.
 */
@Service
public class DevSeedService {

    static final String DEMO_EVENT_TITLE = "PickUP Demo Event";
    private static final String ORGANIZER_EMAIL = "john@test.com";
    private static final String ORGANIZER_NAME = "John Smith";

    private static final List<SeedContact> SEED_CONTACTS = List.of(
            new SeedContact("Jack", ParticipantRole.DRIVER,
                    "Toyota", "Corolla", "black", "A3421", 3,
                    "100 Van Ness Ave, San Francisco, CA", 37.7759, -122.4194),
            new SeedContact("Jacob", ParticipantRole.DRIVER,
                    "Honda", "Civic", "blue", "B9912", 4,
                    "2000 Geary Blvd, San Francisco, CA", 37.7851, -122.4365),
            new SeedContact("Dell", ParticipantRole.PASSENGER,
                    null, null, null, null, null,
                    "123 Main St, San Francisco", 37.7749, -122.4194),
            new SeedContact("James", ParticipantRole.PASSENGER,
                    null, null, null, null, null,
                    "456 Oak Ave, San Francisco", 37.7849, -122.4094),
            new SeedContact("Emma", ParticipantRole.PASSENGER,
                    null, null, null, null, null,
                    "789 Pine St, San Francisco", 37.7912, -122.4011),
            new SeedContact("Noah", ParticipantRole.PASSENGER,
                    null, null, null, null, null,
                    "2200 Mission St, San Francisco", 37.7614, -122.4194),
            new SeedContact("Olivia", ParticipantRole.PASSENGER,
                    null, null, null, null, null,
                    "550 Hayes St, San Francisco", 37.7765, -122.4247),
            new SeedContact("Liam", ParticipantRole.PASSENGER,
                    null, null, null, null, null,
                    "1400 Market St, San Francisco", 37.7760, -122.4177)
    );

    private final DevProperties devProperties;
    private final UserRepository userRepository;
    private final EventRepository eventRepository;
    private final EventParticipantRepository participantRepository;
    private final ContactRepository contactRepository;
    private final VehicleRepository vehicleRepository;
    private final PasswordEncoder passwordEncoder;

    public DevSeedService(DevProperties devProperties,
                          UserRepository userRepository,
                          EventRepository eventRepository,
                          EventParticipantRepository participantRepository,
                          ContactRepository contactRepository,
                          VehicleRepository vehicleRepository,
                          PasswordEncoder passwordEncoder) {
        this.devProperties = devProperties;
        this.userRepository = userRepository;
        this.eventRepository = eventRepository;
        this.participantRepository = participantRepository;
        this.contactRepository = contactRepository;
        this.vehicleRepository = vehicleRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public List<DevAccountInfo> listAccounts() {
        return accountInfos();
    }

    @Transactional
    public DevSeedResponse seed() {
        String password = devProperties.password();
        String hash = passwordEncoder.encode(password);

        UserEntity organizer = ensureOrganizer(hash);

        EventEntity event = eventRepository.findAllByOrganizerId(organizer.getId()).stream()
                .filter(e -> DEMO_EVENT_TITLE.equals(e.getTitle()))
                .findFirst()
                .orElse(null);
        boolean alreadyExisted = event != null;

        if (event == null) {
            event = eventRepository.save(EventEntity.builder()
                    .organizer(organizer)
                    .title(DEMO_EVENT_TITLE)
                    .description("Auto-generated demo event for local testing.")
                    .destinationAddress("Oracle Park, San Francisco")
                    .destinationLat(37.7786)
                    .destinationLng(-122.3893)
                    .eventTime(Instant.now().plus(1, ChronoUnit.DAYS).truncatedTo(ChronoUnit.HOURS))
                    .status(EventStatus.OPEN)
                    .build());
            participantRepository.save(EventParticipantEntity.builder()
                    .event(event)
                    .user(organizer)
                    .role(ParticipantRole.ORGANIZER)
                    .status(ParticipantStatus.CONFIRMED)
                    .build());
        }
        final EventEntity demoEvent = event;

        List<ContactEntity> existingContacts =
                contactRepository.findAllByOrganizerIdAndArchivedAtIsNullOrderByNameAsc(organizer.getId());
        for (SeedContact spec : SEED_CONTACTS) {
            ContactEntity contact = existingContacts.stream()
                    .filter(c -> spec.name().equals(c.getName()))
                    .findFirst()
                    .orElseGet(() -> contactRepository.save(ContactEntity.builder()
                            .organizer(organizer)
                            .name(spec.name())
                            .preferredRole(spec.preferredRole())
                            .defaultAddress(spec.address())
                            .defaultLat(spec.lat())
                            .defaultLng(spec.lng())
                            .build()));

            VehicleEntity vehicle = null;
            if (spec.preferredRole() == ParticipantRole.DRIVER && spec.seats() != null) {
                vehicle = vehicleRepository.findAllByContactIdOrderByCreatedAtAsc(contact.getId()).stream()
                        .filter(v -> spec.make().equals(v.getMake()) && spec.model().equals(v.getModel()))
                        .findFirst()
                        .orElseGet(() -> vehicleRepository.save(VehicleEntity.builder()
                                .contact(contact)
                                .make(spec.make())
                                .model(spec.model())
                                .color(spec.color())
                                .plate(spec.plate())
                                .seats(spec.seats())
                                .build()));
            }

            // Add every seed contact to the demo event as a READY participant so
            // assignment can be exercised immediately without the manual add flow.
            if (participantRepository.findByEventIdAndContactId(demoEvent.getId(), contact.getId()).isEmpty()) {
                participantRepository.save(EventParticipantEntity.builder()
                        .event(demoEvent)
                        .contact(contact)
                        .role(spec.preferredRole())
                        .status(ParticipantStatus.READY)
                        .vehicle(vehicle)
                        .pickupAddress(contact.getDefaultAddress())
                        .pickupLat(contact.getDefaultLat())
                        .pickupLng(contact.getDefaultLng())
                        .build());
            }
        }

        return new DevSeedResponse(demoEvent.getId(), demoEvent.getTitle(), alreadyExisted, accountInfos());
    }

    private UserEntity ensureOrganizer(String passwordHash) {
        return userRepository.findByEmail(ORGANIZER_EMAIL)
                .orElseGet(() -> userRepository.save(UserEntity.builder()
                        .email(ORGANIZER_EMAIL)
                        .passwordHash(passwordHash)
                        .fullName(ORGANIZER_NAME)
                        .systemRoles(EnumSet.of(SystemRole.USER))
                        .build()));
    }

    private List<DevAccountInfo> accountInfos() {
        return List.of(new DevAccountInfo(ORGANIZER_EMAIL, ORGANIZER_NAME, "Organizer", devProperties.password()));
    }

    private record SeedContact(
            String name,
            ParticipantRole preferredRole,
            String make,
            String model,
            String color,
            String plate,
            Integer seats,
            String address,
            Double lat,
            Double lng
    ) {}
}
