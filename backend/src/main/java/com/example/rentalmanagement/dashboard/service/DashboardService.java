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
        List<Invoice> allInvoices = invoices.findAll();
        List<Invoice> monthInvoices = allInvoices.stream()
                .filter(i -> !i.isDeleted)
                .filter(i -> Objects.equals(i.billingMonth, now.getMonthValue()))
                .filter(i -> Objects.equals(i.billingYear, now.getYear()))
                .filter(i -> TENANT_VISIBLE_INVOICE_STATUSES.contains(i.status))
                .toList();
        BigDecimal invoiceAmount = monthInvoices.stream()
                .map(i -> amountOrZero(i.totalAmount))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal collected = monthInvoices.stream()
                .map(i -> amountOrZero(i.paidAmount))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal monthlyDebt = monthInvoices.stream()
                .map(DashboardService::remainingAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal debt = allInvoices.stream()
                .filter(i -> !i.isDeleted)
                .filter(i -> List.of(InvoiceStatus.ISSUED, InvoiceStatus.PARTIALLY_PAID, InvoiceStatus.OVERDUE).contains(i.status))
                .map(DashboardService::remainingAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return new AdminDashboardResponse(
                total,
                rooms.countByStatusAndIsDeletedFalse(RoomStatus.AVAILABLE),
                occupied,
                rooms.countByStatusAndIsDeletedFalse(RoomStatus.MAINTENANCE),
                occupancyRate,
                invoiceAmount,
                collected,
                monthlyDebt,
                debt,
                maintenance.countByStatusInAndIsDeletedFalse(List.of(MaintenanceStatus.OPEN, MaintenanceStatus.RECEIVED, MaintenanceStatus.IN_PROGRESS)),
                contracts.findByStatusAndEndDateBetweenAndIsDeletedFalse(ContractStatus.ACTIVE, now, now.plusDays(30)).size()
        );
    }

    private static BigDecimal amountOrZero(BigDecimal amount) {
        return amount == null ? BigDecimal.ZERO : amount;
    }

    private static BigDecimal remainingAmount(Invoice invoice) {
        return amountOrZero(invoice.totalAmount).subtract(amountOrZero(invoice.paidAmount));
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

    public List<MonthlyRevenueResponse> revenueSummary(Integer requestedYear) {
        int year = requestedYear == null ? LocalDate.now().getYear() : requestedYear;
        if (year < 2000 || year > 2100) {
            throw new BusinessException("Year must be between 2000 and 2100", "DASHBOARD_YEAR_INVALID", HttpStatus.BAD_REQUEST);
        }

        List<Invoice> yearInvoices = invoices.findAll().stream()
                .filter(invoice -> !invoice.isDeleted)
                .filter(invoice -> Objects.equals(invoice.billingYear, year))
                .filter(invoice -> TENANT_VISIBLE_INVOICE_STATUSES.contains(invoice.status))
                .toList();
        List<MonthlyRevenueResponse> result = new ArrayList<>(12);
        for (int month = 1; month <= 12; month++) {
            final int currentMonth = month;
            List<Invoice> monthInvoices = yearInvoices.stream()
                    .filter(invoice -> Objects.equals(invoice.billingMonth, currentMonth))
                    .toList();
            BigDecimal total = monthInvoices.stream()
                    .map(invoice -> amountOrZero(invoice.totalAmount))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal collected = monthInvoices.stream()
                    .map(invoice -> amountOrZero(invoice.paidAmount))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal debt = monthInvoices.stream()
                    .map(DashboardService::remainingAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            long paidInvoices = monthInvoices.stream()
                    .filter(invoice -> invoice.status == InvoiceStatus.PAID)
                    .count();
            result.add(new MonthlyRevenueResponse(
                    month,
                    year,
                    total,
                    collected,
                    debt,
                    monthInvoices.size(),
                    paidInvoices
            ));
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
