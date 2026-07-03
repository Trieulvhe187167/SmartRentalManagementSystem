package com.example.rentalmanagement.meterreading;

import java.nio.charset.*;
import com.example.rentalmanagement.common.scheduling.*;

import java.math.*;
import java.time.*;
import java.util.*;
import java.io.*;
import javax.crypto.*;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import com.example.rentalmanagement.common.api.*;
import com.example.rentalmanagement.common.audit.*;
import com.example.rentalmanagement.common.enums.*;
import com.example.rentalmanagement.common.exception.*;
import com.example.rentalmanagement.common.security.*;
import com.example.rentalmanagement.auth.dto.*;
import com.example.rentalmanagement.auth.service.*;
import com.example.rentalmanagement.building.*;
import com.example.rentalmanagement.building.dto.*;
import com.example.rentalmanagement.building.repository.*;
import com.example.rentalmanagement.building.service.*;
import com.example.rentalmanagement.contract.*;
import com.example.rentalmanagement.contract.dto.*;
import com.example.rentalmanagement.contract.repository.*;
import com.example.rentalmanagement.contract.service.*;
import com.example.rentalmanagement.dashboard.dto.*;
import com.example.rentalmanagement.dashboard.service.*;
import com.example.rentalmanagement.invoice.*;
import com.example.rentalmanagement.invoice.dto.*;
import com.example.rentalmanagement.invoice.repository.*;
import com.example.rentalmanagement.invoice.service.*;
import com.example.rentalmanagement.maintenance.*;
import com.example.rentalmanagement.maintenance.dto.*;
import com.example.rentalmanagement.maintenance.repository.*;
import com.example.rentalmanagement.maintenance.service.*;
import com.example.rentalmanagement.notification.*;
import com.example.rentalmanagement.notification.dto.*;
import com.example.rentalmanagement.notification.repository.*;
import com.example.rentalmanagement.notification.service.*;
import com.example.rentalmanagement.payment.*;
import com.example.rentalmanagement.payment.dto.*;
import com.example.rentalmanagement.payment.repository.*;
import com.example.rentalmanagement.room.*;
import com.example.rentalmanagement.room.dto.*;
import com.example.rentalmanagement.room.repository.*;
import com.example.rentalmanagement.serviceitem.*;
import com.example.rentalmanagement.serviceitem.dto.*;
import com.example.rentalmanagement.serviceitem.repository.*;
import com.example.rentalmanagement.tenant.*;
import com.example.rentalmanagement.tenant.dto.*;
import com.example.rentalmanagement.tenant.repository.*;
import com.example.rentalmanagement.user.*;
import com.example.rentalmanagement.user.dto.*;
import com.example.rentalmanagement.user.repository.*;

@Entity
@Table(name = "meter_readings", uniqueConstraints = @UniqueConstraint(columnNames = {"room_id", "service_id", "billing_year", "billing_month"}))
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class MeterReading extends IdEntity {
    @ManyToOne(optional = false)
    @JoinColumn(name = "room_id")
    public Room room;
    @ManyToOne(optional = false)
    @JoinColumn(name = "service_id")
    public ServiceItem serviceItem;
    @Column(nullable = false)
    public Integer billingMonth;
    @Column(nullable = false)
    public Integer billingYear;
    @Column(nullable = false, precision = 14, scale = 3)
    public BigDecimal previousReading;
    @Column(nullable = false, precision = 14, scale = 3)
    public BigDecimal currentReading;
    @Column(precision = 14, scale = 3, insertable = false, updatable = false)
    public BigDecimal consumption;
    @Column(nullable = false)
    public LocalDate readingDate;
    @ManyToOne(optional = false)
    @JoinColumn(name = "recorded_by")
    public User recordedBy;
    public String notes;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public MeterReadingStatus status = MeterReadingStatus.DRAFT;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;
    public Long updatedBy;
    public boolean isDeleted;
    public LocalDateTime deletedAt;

    @PrePersist
    public void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    public void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
