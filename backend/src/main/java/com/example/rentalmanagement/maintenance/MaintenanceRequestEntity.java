package com.example.rentalmanagement.maintenance;

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
import com.example.rentalmanagement.meterreading.*;
import com.example.rentalmanagement.meterreading.dto.*;
import com.example.rentalmanagement.meterreading.repository.*;
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
@Table(name = "maintenance_requests")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class MaintenanceRequestEntity extends AuditableEntity {
    @Column(nullable = false, unique = true, length = 50)
    public String requestNumber;
    @ManyToOne(optional = false)
    @JoinColumn(name = "contract_id")
    public RentalContract contract;
    @ManyToOne(optional = false)
    @JoinColumn(name = "room_id")
    public Room room;
    @ManyToOne(optional = false)
    @JoinColumn(name = "requester_user_id")
    public User requesterUser;
    @Column(nullable = false, length = 200)
    public String title;
    @Column(nullable = false, columnDefinition = "TEXT")
    public String description;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public MaintenancePriority priority = MaintenancePriority.MEDIUM;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    public MaintenanceStatus status = MaintenanceStatus.OPEN;
    @Column(columnDefinition = "TEXT")
    public String resolutionSummary;
    public String rejectedReason;
    public LocalDateTime submittedAt;
    public LocalDateTime receivedAt;
    public LocalDateTime resolvedAt;
    public LocalDateTime cancelledAt;
}
