package com.example.rentalmanagement.dashboard.service;

import java.nio.charset.*;
import com.example.rentalmanagement.common.scheduling.*;

import java.math.*;
import java.time.*;
import java.util.*;
import java.io.*;
import javax.crypto.*;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
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

@Service
public class DashboardService {
    private static final List<InvoiceStatus> TENANT_VISIBLE_INVOICE_STATUSES = List.of(
            InvoiceStatus.ISSUED,
            InvoiceStatus.PARTIALLY_PAID,
            InvoiceStatus.PAID,
            InvoiceStatus.OVERDUE
    );

    private final RoomRepository rooms;
    private final InvoiceRepository invoices;
    private final MaintenanceRequestRepository maintenance;
    private final RentalContractRepository contracts;
    private final CurrentUser currentUser;
    private final NotificationRepository notifications;

    public DashboardService(RoomRepository rooms, InvoiceRepository invoices, MaintenanceRequestRepository maintenance, RentalContractRepository contracts, CurrentUser currentUser, NotificationRepository notifications) {
        this.rooms = rooms;
        this.invoices = invoices;
        this.maintenance = maintenance;
        this.contracts = contracts;
        this.currentUser = currentUser;
        this.notifications = notifications;
    }

    public AdminDashboardResponse adminSummary() {
        long total = rooms.countByIsDeletedFalse();
        long occupied = rooms.countByStatusAndIsDeletedFalse(RoomStatus.OCCUPIED);
        BigDecimal occupancyRate = total == 0 ? BigDecimal.ZERO : BigDecimal.valueOf(occupied * 100.0 / total).setScale(2, RoundingMode.HALF_UP);
        LocalDate now = LocalDate.now();
        List<Invoice> monthInvoices = invoices.findAll().stream()
                .filter(i -> i.billingMonth == now.getMonthValue() && i.billingYear == now.getYear() && i.status != InvoiceStatus.CANCELLED)
                .toList();
        BigDecimal invoiceAmount = monthInvoices.stream().map(i -> i.totalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal collected = monthInvoices.stream().map(i -> i.paidAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal debt = invoices.findAll().stream()
                .filter(i -> List.of(InvoiceStatus.ISSUED, InvoiceStatus.PARTIALLY_PAID, InvoiceStatus.OVERDUE).contains(i.status))
                .map(i -> i.totalAmount.subtract(i.paidAmount))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return new AdminDashboardResponse(
                total,
                rooms.countByStatusAndIsDeletedFalse(RoomStatus.AVAILABLE),
                occupied,
                rooms.countByStatusAndIsDeletedFalse(RoomStatus.MAINTENANCE),
                occupancyRate,
                invoiceAmount,
                collected,
                debt,
                maintenance.countByStatusInAndIsDeletedFalse(List.of(MaintenanceStatus.OPEN, MaintenanceStatus.RECEIVED, MaintenanceStatus.IN_PROGRESS)),
                contracts.findByStatusAndEndDateBetweenAndIsDeletedFalse(ContractStatus.ACTIVE, now, now.plusDays(30)).size()
        );
    }

    public java.util.Map<String, Long> roomStats() {
        return java.util.Map.of(
                "totalRooms", rooms.countByIsDeletedFalse(),
                "availableRooms", rooms.countByStatusAndIsDeletedFalse(RoomStatus.AVAILABLE),
                "occupiedRooms", rooms.countByStatusAndIsDeletedFalse(RoomStatus.OCCUPIED),
                "maintenanceRooms", rooms.countByStatusAndIsDeletedFalse(RoomStatus.MAINTENANCE),
                "inactiveRooms", rooms.countByStatusAndIsDeletedFalse(RoomStatus.INACTIVE)
        );
    }

    public java.util.Map<String, BigDecimal> revenueSummary() {
        java.util.Map<String, BigDecimal> result = new java.util.HashMap<>();
        for (Invoice i : invoices.findAll()) {
            if (i.isDeleted == false && i.billingYear != null && i.billingMonth != null && i.status != InvoiceStatus.CANCELLED) {
                String key = String.format("%d-%02d", i.billingYear, i.billingMonth);
                BigDecimal currentVal = result.getOrDefault(key, BigDecimal.ZERO);
                BigDecimal paid = i.paidAmount != null ? i.paidAmount : BigDecimal.ZERO;
                result.put(key, currentVal.add(paid));
            }
        }
        return result;
    }

    public List<RentalContract> expiringContracts() {
        LocalDate now = LocalDate.now();
        return contracts.findByStatusAndEndDateBetweenAndIsDeletedFalse(ContractStatus.ACTIVE, now, now.plusDays(30));
    }

    public Page<MaintenanceRequestEntity> openMaintenance(Pageable pageable) {
        return maintenance.findByStatusAndIsDeletedFalse(MaintenanceStatus.OPEN, pageable);
    }

    public TenantDashboardResponse tenantSummary() {
        Long userId = currentUser.userId();
        RentalContract contract = contracts.findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalse(userId, ContractStatus.ACTIVE).orElse(null);
        Invoice latest = invoices.findByTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                        userId,
                        TENANT_VISIBLE_INVOICE_STATUSES,
                        PageRequest.of(0, 1, Sort.by(Sort.Direction.DESC, "createdAt"))
                )
                .stream().findFirst().orElse(null);
        BigDecimal debt = invoices.findByTenantProfileUserIdAndIsDeletedFalse(userId, Pageable.unpaged()).stream()
                .filter(i -> List.of(InvoiceStatus.ISSUED, InvoiceStatus.PARTIALLY_PAID, InvoiceStatus.OVERDUE).contains(i.status))
                .map(i -> i.totalAmount.subtract(i.paidAmount))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return new TenantDashboardResponse(contract, contract == null ? null : contract.room, latest, debt, notifications.countByUserIdAndIsReadFalse(userId));
    }
}
