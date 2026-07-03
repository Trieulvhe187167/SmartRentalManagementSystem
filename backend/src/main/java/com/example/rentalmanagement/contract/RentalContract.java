package com.example.rentalmanagement.contract;

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
@Table(name = "rental_contracts")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class RentalContract extends AuditableEntity {
    @Column(nullable = false, unique = true, length = 50)
    public String contractCode;
    @ManyToOne(optional = false)
    @JoinColumn(name = "room_id")
    public Room room;
    @ManyToOne(optional = false)
    @JoinColumn(name = "primary_tenant_id")
    public TenantProfile primaryTenant;
    @ManyToOne
    @JoinColumn(name = "renewed_from_contract_id")
    public RentalContract renewedFromContract;
    @Column(nullable = false)
    public LocalDate startDate;
    @Column(nullable = false)
    public LocalDate endDate;
    @Column(nullable = false, precision = 18, scale = 2)
    public BigDecimal appliedRent;
    @Column(nullable = false, precision = 18, scale = 2)
    public BigDecimal depositAmount = BigDecimal.ZERO;
    @Column(nullable = false)
    public Integer monthlyDueDay = 5;
    @Column(columnDefinition = "TEXT")
    public String terms;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public ContractStatus status = ContractStatus.DRAFT;
    public LocalDateTime activatedAt;
    @Column(name = "ended_at")
    public LocalDateTime endedAt;
    public String terminationReason;
    @Column(insertable = false, updatable = false)
    public Long activeRoomId;
}
