package com.example.rentalmanagement.invoice.service;

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
import com.example.rentalmanagement.dashboard.service.*;
import com.example.rentalmanagement.invoice.*;
import com.example.rentalmanagement.invoice.dto.*;
import com.example.rentalmanagement.invoice.repository.*;
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
public class BillingService {
    private static final List<InvoiceStatus> TENANT_VISIBLE_INVOICE_STATUSES = List.of(
            InvoiceStatus.ISSUED,
            InvoiceStatus.PARTIALLY_PAID,
            InvoiceStatus.PAID,
            InvoiceStatus.OVERDUE
    );

    private final RoomRepository rooms;
    private final RentalContractRepository contracts;
    private final ServiceItemRepository services;
    private final ServicePriceRepository prices;
    private final ContractServiceRepository contractServices;
    private final ContractOccupantRepository contractOccupants;
    private final MeterReadingRepository readings;
    private final InvoiceRepository invoices;
    private final InvoiceItemRepository items;
    private final PaymentRepository payments;
    private final DatabaseProcedureRepository procedures;
    private final NotificationService notifications;
    private final CurrentUser currentUser;
    private final UserRepository users;
    private final EntityManager entityManager;

    public BillingService(RoomRepository rooms, RentalContractRepository contracts, ServiceItemRepository services, ServicePriceRepository prices, ContractServiceRepository contractServices, ContractOccupantRepository contractOccupants, MeterReadingRepository readings, InvoiceRepository invoices, InvoiceItemRepository items, PaymentRepository payments, DatabaseProcedureRepository procedures, NotificationService notifications, CurrentUser currentUser, UserRepository users, EntityManager entityManager) {
        this.rooms = rooms;
        this.contracts = contracts;
        this.services = services;
        this.prices = prices;
        this.contractServices = contractServices;
        this.contractOccupants = contractOccupants;
        this.readings = readings;
        this.invoices = invoices;
        this.items = items;
        this.payments = payments;
        this.procedures = procedures;
        this.notifications = notifications;
        this.currentUser = currentUser;
        this.users = users;
        this.entityManager = entityManager;
    }

    @Transactional
    public MeterReading saveReading(MeterReadingRequest request) {
        Room room = rooms.findById(request.roomId()).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        ServiceItem service = services.findById(request.serviceId()).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        if (service.chargeType != ServiceChargeType.METERED) {
            throw new BusinessException("Service must be metered", "SERVICE_NOT_METERED");
        }
        if (readings.existsByRoomIdAndServiceItemIdAndBillingMonthAndBillingYearAndIsDeletedFalse(room.id, service.id, request.billingMonth(), request.billingYear())) {
            throw new BusinessException("Meter reading already exists for the period", "METER_READING_DUPLICATED");
        }
        if (request.currentReading().compareTo(request.previousReading()) < 0) {
            throw new BusinessException("Current reading is smaller than previous reading", "METER_READING_INVALID_INDEX");
        }
        MeterReading reading = new MeterReading();
        reading.room = room;
        reading.serviceItem = service;
        reading.billingMonth = request.billingMonth();
        reading.billingYear = request.billingYear();
        reading.previousReading = request.previousReading();
        reading.currentReading = request.currentReading();
        reading.readingDate = request.readingDate();
        reading.notes = request.notes();
        reading.recordedBy = currentUser.requireUser();
        reading.status = MeterReadingStatus.DRAFT;
        return readings.save(reading);
    }

    public Page<MeterReading> readings(Pageable pageable) {
        return readings.findAll(pageable);
    }

    public MeterReading reading(Long id) {
        return readings.findById(id).orElseThrow(() -> new NotFoundException("Meter reading not found", "METER_READING_NOT_FOUND"));
    }

    public MeterReading latestRoomReading(Long roomId, Long serviceId) {
        Optional<MeterReading> latest = serviceId == null
                ? readings.findFirstByRoomIdAndIsDeletedFalseOrderByBillingYearDescBillingMonthDescReadingDateDesc(roomId)
                : readings.findFirstByRoomIdAndServiceItemIdAndIsDeletedFalseOrderByBillingYearDescBillingMonthDescReadingDateDesc(roomId, serviceId);
        return latest
                .orElseThrow(() -> new NotFoundException("Meter reading not found", "METER_READING_NOT_FOUND"));
    }

    @Transactional
    public MeterReading updateReading(Long id, MeterReadingRequest request) {
        MeterReading reading = reading(id);
        if (reading.status == MeterReadingStatus.LOCKED) {
            throw new BusinessException("A locked meter reading cannot be edited", "METER_READING_LOCKED");
        }
        if (request.currentReading().compareTo(request.previousReading()) < 0) {
            throw new BusinessException("Current reading is smaller than previous reading", "METER_READING_INVALID_INDEX");
        }
        reading.room = rooms.findById(request.roomId()).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        reading.serviceItem = services.findById(request.serviceId()).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        reading.billingMonth = request.billingMonth();
        reading.billingYear = request.billingYear();
        reading.previousReading = request.previousReading();
        reading.currentReading = request.currentReading();
        reading.readingDate = request.readingDate();
        reading.notes = request.notes();
        reading.updatedBy = currentUser.userId();
        return reading;
    }

    @Transactional
    public MeterReading cancelReading(Long id) {
        MeterReading reading = reading(id);
        reading.status = MeterReadingStatus.CANCELLED;
        reading.updatedBy = currentUser.userId();
        return reading;
    }

    public Page<MeterReading> tenantReadings(Pageable pageable) {
        RentalContract contract = contracts.findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalse(currentUser.userId(), ContractStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Current contract not found", "CONTRACT_NOT_FOUND"));
        return readings.findByRoomIdAndIsDeletedFalse(contract.room.id, pageable);
    }

    @Transactional
    public Invoice generateInvoice(GenerateInvoiceRequest request) {
        RentalContract contract = contracts.findById(request.contractId()).orElseThrow(() -> new NotFoundException("Contract not found", "CONTRACT_NOT_FOUND"));
        if (contract.status != ContractStatus.ACTIVE) {
            throw new BusinessException("Only active contracts can generate invoices", "CONTRACT_NOT_ACTIVE");
        }
        if (invoices.existsByContractIdAndBillingMonthAndBillingYearAndStatusNotAndIsDeletedFalse(contract.id, request.billingMonth(), request.billingYear(), InvoiceStatus.CANCELLED)) {
            throw new BusinessException("Invoice already exists for the period", "INVOICE_ALREADY_EXISTS");
        }
        Invoice invoice = new Invoice();
        invoice.invoiceNumber = "INV-" + contract.contractCode + "-" + request.billingYear() + String.format("%02d", request.billingMonth());
        invoice.contract = contract;
        invoice.room = contract.room;
        invoice.tenantProfile = contract.primaryTenant;
        invoice.billingMonth = request.billingMonth();
        invoice.billingYear = request.billingYear();
        invoice.dueDate = ScheduledJobs.dueDate(request.billingYear(), request.billingMonth(), contract.monthlyDueDay);
        invoice.status = InvoiceStatus.DRAFT;
        invoice = invoices.save(invoice);

        addItem(invoice, InvoiceItemType.RENT, "Monthly room rent", BigDecimal.ONE, "month", contract.appliedRent, null, null, null, null);
        LocalDate billingDate = LocalDate.of(request.billingYear(), request.billingMonth(), 1);
        int displayOrder = 1;
        for (ContractService cs : contractServices.findByContractIdAndStatusAndIsDeletedFalse(contract.id, RecordStatus.ACTIVE)) {
            ServicePrice price = prices.findEffective(cs.serviceItem.id, billingDate).stream()
                    .findFirst()
                    .orElseThrow(() -> new NotFoundException("No effective service price found", "SERVICE_PRICE_NOT_FOUND"));
            BigDecimal qty;
            InvoiceItemType type;
            MeterReading meterReading = null;
            if (cs.serviceItem.chargeType == ServiceChargeType.METERED) {
                MeterReading reading = readings.findByRoomIdAndServiceItemIdAndBillingMonthAndBillingYearAndIsDeletedFalse(contract.room.id, cs.serviceItem.id, request.billingMonth(), request.billingYear())
                        .orElseThrow(() -> new BusinessException(
                                "Missing meter reading for room " + contract.room.roomNumber
                                        + ", service " + cs.serviceItem.name
                                        + ", period " + request.billingMonth() + "/" + request.billingYear(),
                                "METER_READING_NOT_FOUND",
                                HttpStatus.BAD_REQUEST));
                qty = reading.currentReading.subtract(reading.previousReading);
                type = InvoiceItemType.METERED_SERVICE;
                meterReading = reading;
            } else if (cs.serviceItem.chargeType == ServiceChargeType.FIXED_PER_PERSON) {
                qty = residentQuantity(contract.id, billingDate);
                type = InvoiceItemType.FIXED_SERVICE;
            } else {
                qty = BigDecimal.ONE;
                type = InvoiceItemType.FIXED_SERVICE;
            }
            addItem(invoice, type, cs.serviceItem.name, qty, cs.serviceItem.unit, price.unitPrice, displayOrder++, cs.serviceItem, cs, meterReading);
        }
        entityManager.flush();
        entityManager.refresh(invoice);
        return invoice;
    }

    BigDecimal residentQuantity(Long contractId, LocalDate billingDate) {
        return BigDecimal.valueOf(1 + contractOccupants.countActiveOnDate(contractId, billingDate));
    }

    @Transactional
    public List<Invoice> generateMonthly(GenerateMonthlyInvoicesRequest request) {
        return contracts.findByStatusAndIsDeletedFalse(ContractStatus.ACTIVE).stream()
                .filter(c -> !invoices.existsByContractIdAndBillingMonthAndBillingYearAndStatusNotAndIsDeletedFalse(c.id, request.billingMonth(), request.billingYear(), InvoiceStatus.CANCELLED))
                .map(c -> generateInvoice(new GenerateInvoiceRequest(c.id, request.billingMonth(), request.billingYear())))
                .toList();
    }

    @Transactional
    public Invoice addAdjustment(Long invoiceId, InvoiceAdjustmentRequest request) {
        Invoice invoice = invoice(invoiceId);
        ensureDraft(invoice);
        if (request.quantity().compareTo(BigDecimal.ZERO) == 0) {
            throw new BusinessException("Quantity must be greater than zero", "INVOICE_ITEM_INVALID_QUANTITY", HttpStatus.BAD_REQUEST);
        }
        BigDecimal unitPrice = request.amount().divide(request.quantity(), 2, RoundingMode.HALF_UP);
        addItem(invoice, InvoiceItemType.ADJUSTMENT, request.description(), request.quantity(), request.unit() == null ? "adjustment" : request.unit(), unitPrice, null, null, null, null);
        entityManager.flush();
        entityManager.refresh(invoice);
        return invoice;
    }

    @Transactional
    public Invoice issue(Long invoiceId, InvoiceIssueRequest request) {
        Invoice invoice = invoice(invoiceId);
        ensureDraft(invoice);
        invoice.issueDate = request.issueDate();
        invoice.dueDate = request.dueDate();
        invoice.status = InvoiceStatus.ISSUED;
        invoice.issuedAt = LocalDateTime.now();
        notifications.create(invoice.contract.primaryTenant.user, NotificationType.INVOICE_ISSUED, "Invoice issued", "Invoice " + invoice.invoiceNumber + " has been issued.");
        return invoice;
    }

    @Transactional
    public Invoice cancel(Long invoiceId, InvoiceCancelRequest request) {
        Invoice invoice = invoice(invoiceId);
        if (!payments.findByInvoiceIdAndStatus(invoice.id, PaymentStatus.CONFIRMED).isEmpty()) {
            throw new BusinessException("Invoice has payment records", "INVOICE_HAS_PAYMENTS");
        }
        invoice.status = InvoiceStatus.CANCELLED;
        invoice.cancelledAt = LocalDateTime.now();
        invoice.cancellationReason = request == null ? null : request.cancellationReason();
        return invoice;
    }

    public Invoice invoice(Long id) {
        return invoices.findById(id).orElseThrow(() -> new NotFoundException("Invoice not found", "INVOICE_NOT_FOUND"));
    }

    public InvoiceDetail invoiceDetail(Long id) {
        Invoice invoice = invoice(id);
        return new InvoiceDetail(invoice, items.findByInvoiceIdAndIsDeletedFalseOrderByDisplayOrderAsc(id), payments.findByInvoiceIdOrderByPaymentDateDesc(id));
    }

    public Page<Invoice> invoices(InvoiceStatus status, Integer month, Integer year, Long tenantId, Pageable pageable) {
        return invoices.search(status, month, year, tenantId, pageable);
    }

    @Transactional
    public Invoice updateItems(Long invoiceId, InvoiceItemsUpdateRequest request) {
        Invoice invoice = invoice(invoiceId);
        ensureDraft(invoice);
        items.deleteByInvoiceId(invoiceId);
        int order = 0;
        if (request.items() != null) {
            for (InvoiceItemUpdateRequest item : request.items()) {
                ServiceItem serviceItem = item.serviceId() == null ? null : services.findById(item.serviceId()).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
                ContractService contractService = item.contractServiceId() == null ? null : contractServices.findById(item.contractServiceId()).orElseThrow(() -> new NotFoundException("Contract service not found", "CONTRACT_SERVICE_NOT_FOUND"));
                MeterReading meterReading = item.meterReadingId() == null ? null : readings.findById(item.meterReadingId()).orElseThrow(() -> new NotFoundException("Meter reading not found", "METER_READING_NOT_FOUND"));
                addItem(invoice, item.itemType(), item.description(), item.quantity(), item.unit(), item.unitPrice(), item.displayOrder() == null ? order++ : item.displayOrder(), serviceItem, contractService, meterReading);
            }
        }
        entityManager.flush();
        entityManager.refresh(invoice);
        return invoice;
    }

    public Page<Invoice> tenantInvoices(Pageable pageable) {
        return invoices.findByTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                currentUser.userId(),
                TENANT_VISIBLE_INVOICE_STATUSES,
                pageable
        );
    }

    public Page<Invoice> tenantDebtInvoices(Pageable pageable) {
        return invoices.findByTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                currentUser.userId(),
                List.of(InvoiceStatus.ISSUED, InvoiceStatus.PARTIALLY_PAID, InvoiceStatus.OVERDUE),
                pageable
        );
    }

    public InvoiceDetail tenantInvoice(Long id) {
        Invoice invoice = invoices.findByIdAndTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                        id,
                        currentUser.userId(),
                        TENANT_VISIBLE_INVOICE_STATUSES
                )
                .orElseThrow(() -> new NotFoundException("Invoice not found", "INVOICE_NOT_FOUND"));
        return new InvoiceDetail(invoice, items.findByInvoiceIdAndIsDeletedFalseOrderByDisplayOrderAsc(id), payments.findByInvoiceIdAndStatus(id, PaymentStatus.CONFIRMED));
    }

    @Transactional
    public Payment recordPayment(Long invoiceId, PaymentCreateRequest request) {
        Invoice invoice = invoice(invoiceId);
        if (invoice.status == InvoiceStatus.CANCELLED) {
            throw new BusinessException("Invoice is cancelled", "INVOICE_CANCELLED");
        }
        if (invoice.status == InvoiceStatus.DRAFT) {
            throw new BusinessException("A draft invoice cannot receive payments", "INVOICE_NOT_ISSUED");
        }
        BigDecimal remaining = invoice.totalAmount.subtract(invoice.paidAmount);
        if (request.amount().compareTo(remaining) > 0) {
            throw new BusinessException("Payment amount exceeds remaining debt", "PAYMENT_EXCEEDS_REMAINING_AMOUNT");
        }
        Payment payment = new Payment();
        User admin = currentUser.requireUser();
        payment.paymentNumber = "PAY-" + invoice.invoiceNumber + "-" + System.currentTimeMillis();
        payment.invoice = invoice;
        payment.amount = request.amount();
        payment.paymentDate = request.paymentDate().atStartOfDay();
        payment.method = request.method();
        payment.transactionReference = request.transactionReference();
        payment.notes = request.notes();
        payment.status = PaymentStatus.CONFIRMED;
        payment.confirmedBy = admin;
        payment.createdBy = admin.id;
        payment = payments.save(payment);
        entityManager.flush();
        entityManager.refresh(invoice);
        notifications.create(invoice.contract.primaryTenant.user, NotificationType.PAYMENT_CONFIRMED, "Payment confirmed", "Payment for invoice " + invoice.invoiceNumber + " has been confirmed.");
        return payment;
    }

    @Transactional
    public Payment cancelPayment(Long id, PaymentCancelRequest request) {
        Payment payment = payments.findById(id).orElseThrow(() -> new NotFoundException("Payment not found", "PAYMENT_NOT_FOUND"));
        if (payment.status != PaymentStatus.CONFIRMED) {
            throw new BusinessException("Only confirmed payments can be cancelled", "PAYMENT_NOT_CONFIRMED");
        }
        payment.status = PaymentStatus.CANCELLED;
        payment.cancellationReason = request.cancellationReason();
        payment.cancelledAt = LocalDateTime.now();
        payment.cancelledBy = currentUser.requireUser();
        entityManager.flush();
        entityManager.refresh(payment.invoice);
        return payment;
    }

    public Page<Payment> payments(Long invoiceId, PaymentStatus status, Pageable pageable) {
        return payments.search(invoiceId, status, pageable);
    }

    public Payment payment(Long id) {
        return payments.findById(id).orElseThrow(() -> new NotFoundException("Payment not found", "PAYMENT_NOT_FOUND"));
    }

    public Page<Payment> tenantPayments(Pageable pageable) {
        return payments.findByInvoiceTenantProfileUserId(currentUser.userId(), pageable);
    }

    public Page<Invoice> debts(Integer month, Integer year, Pageable pageable) {
        return invoices.debts(
                List.of(InvoiceStatus.ISSUED, InvoiceStatus.PARTIALLY_PAID, InvoiceStatus.OVERDUE),
                month,
                year,
                pageable
        );
    }

    private void ensureDraft(Invoice invoice) {
        if (invoice.status != InvoiceStatus.DRAFT) {
            throw new BusinessException("Invoice cannot be edited in current status", "INVOICE_NOT_EDITABLE");
        }
    }

    private void addItem(Invoice invoice, InvoiceItemType type, String description, BigDecimal quantity, String unit, BigDecimal unitPrice, Integer displayOrder, ServiceItem serviceItem, ContractService contractService, MeterReading meterReading) {
        InvoiceItem item = new InvoiceItem();
        item.invoice = invoice;
        item.itemType = type;
        item.serviceItem = serviceItem;
        item.contractService = contractService;
        item.meterReading = meterReading;
        item.description = description;
        item.quantity = quantity;
        item.unit = unit;
        item.unitPrice = unitPrice;
        item.amount = quantity.multiply(unitPrice).setScale(2, RoundingMode.HALF_UP);
        item.displayOrder = displayOrder == null ? 0 : displayOrder;
        items.save(item);
    }

    @Transactional
    public void markOverdueInvoices() {
        List<Invoice> becomingOverdue = invoices.findByStatusInAndDueDateBeforeAndIsDeletedFalse(List.of(InvoiceStatus.ISSUED, InvoiceStatus.PARTIALLY_PAID), LocalDate.now());
        procedures.markOverdueInvoices();
        becomingOverdue.forEach(invoice ->
                notifications.create(invoice.contract.primaryTenant.user, NotificationType.INVOICE_OVERDUE, "Invoice " + invoice.invoiceNumber + " overdue", "Invoice " + invoice.invoiceNumber + " is overdue.")
        );
    }
}
