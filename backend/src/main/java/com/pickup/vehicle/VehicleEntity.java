package com.pickup.vehicle;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.pickup.common.domain.BaseEntity;
import com.pickup.contact.ContactEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "vehicles")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class VehicleEntity extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    /** Phase 4D-1: vehicles are owned by the organizer-managed Contact, not a User. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "contact_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_vehicles_contact"))
    private ContactEntity contact;

    /** Optional friendly name shown in pickers, e.g. "Craig's Honda". */
    @Column
    private String label;

    @Column(nullable = false)
    private String make;

    @Column(nullable = false)
    private String model;

    @Column
    private String color;

    @Column
    private String plate;

    @Column(nullable = false)
    private int seats;

    @Column(columnDefinition = "text")
    private String notes;
}
