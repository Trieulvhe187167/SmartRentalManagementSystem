package com.example.rentalmanagement.invoice;

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
@Table(name = "invoices")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Invoice extends AuditableEntity {
    @Column(name = "invoice_number", nullable = false, unique = true, length = 50)
    public String invoiceNumber;
    @ManyToOne(optional = false)
    @JoinColumn(name = "contract_id")
    public RentalContract contract;
    @ManyToOne(optional = false)
    @JoinColumn(name = "room_id")
    public Room room;
    @ManyToOne(optional = false)
    @JoinColumn(name = "tenant_profile_id")
    public TenantProfile tenantProfile;
    @Column(nullable = false)
    public Integer billingMonth;
    @Column(nullable = false)
    public Integer billingYear;
    public LocalDate issueDate;
    @Column(nullable = false)
    public LocalDate dueDate;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    public InvoiceStatus status = InvoiceStatus.DRAFT;
    @Column(nullable = false, precision = 18, scale = 2, insertable = false)
    public BigDecimal totalAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2, insertable = false)
    public BigDecimal paidAmount = BigDecimal.ZERO;
    @Column(precision = 18, scale = 2, insertable = false, updatable = false)
    public BigDecimal remainingAmount;
    public String notes;
    public LocalDateTime issuedAt;
    public LocalDateTime cancelledAt;
    public String cancellationReason;
    @Column(insertable = false, updatable = false)
    public Long currentContractId;
    @Column(insertable = false, updatable = false)
    public Integer currentBillingYear;
    @Column(insertable = false, updatable = false)
    public Integer currentBillingMonth;
}
