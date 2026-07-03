package com.example.rentalmanagement.payment;

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
import com.example.rentalmanagement.meterreading.*;
import com.example.rentalmanagement.meterreading.dto.*;
import com.example.rentalmanagement.meterreading.repository.*;
import com.example.rentalmanagement.notification.*;
import com.example.rentalmanagement.notification.dto.*;
import com.example.rentalmanagement.notification.repository.*;
import com.example.rentalmanagement.notification.service.*;
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
@Table(name = "payments")
@EntityListeners(AuditEntityListener.class)
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Payment extends IdEntity {
    @Column(nullable = false, unique = true, length = 50)
    public String paymentNumber;
    @ManyToOne(optional = false)
    @JoinColumn(name = "invoice_id")
    public Invoice invoice;
    @Column(nullable = false, precision = 18, scale = 2)
    public BigDecimal amount;
    @Column(nullable = false)
    public LocalDateTime paymentDate;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    public PaymentMethod method;
    public String transactionReference;
    public String notes;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public PaymentStatus status = PaymentStatus.CONFIRMED;
    @ManyToOne(optional = false)
    @JoinColumn(name = "confirmed_by")
    public User confirmedBy;
    public LocalDateTime cancelledAt;
    @ManyToOne
    @JoinColumn(name = "cancelled_by")
    public User cancelledBy;
    public String cancellationReason;
    public LocalDateTime createdAt;
    public Long createdBy;
    public LocalDateTime updatedAt;
    public Long updatedBy;

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
