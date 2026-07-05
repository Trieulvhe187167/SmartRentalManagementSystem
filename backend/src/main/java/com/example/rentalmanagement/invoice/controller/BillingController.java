package com.example.rentalmanagement.invoice.controller;

import java.nio.charset.*;
import com.example.rentalmanagement.common.scheduling.*;

import java.math.*;
import java.time.*;
import java.util.*;
import java.io.*;
import javax.crypto.*;

import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
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

@RestController
@RequestMapping("/api/v1")
public class BillingController {
    private final BillingService billing;

    public BillingController(BillingService billing) {
        this.billing = billing;
    }

    @PostMapping("/admin/meter-readings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MeterReading> reading(@Valid @RequestBody MeterReadingRequest request) {
        return ApiResponse.success("Created", billing.saveReading(request));
    }

    @GetMapping("/admin/meter-readings")
    public ApiResponse<PageResponse<MeterReading>> readings(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.readings(pageable)));
    }

    @GetMapping("/admin/meter-readings/{id}")
    public ApiResponse<MeterReading> reading(@PathVariable Long id) {
        return ApiResponse.success(billing.reading(id));
    }

    @GetMapping("/admin/rooms/{roomId}/meter-readings/latest")
    public ApiResponse<MeterReading> latestRoomReading(@PathVariable Long roomId,
                                                       @RequestParam(required = false) Long serviceId) {
        return ApiResponse.success(billing.latestRoomReading(roomId, serviceId));
    }

    @PutMapping("/admin/meter-readings/{id}")
    public ApiResponse<MeterReading> updateReading(@PathVariable Long id, @Valid @RequestBody MeterReadingRequest request) {
        return ApiResponse.success(billing.updateReading(id, request));
    }

    @PutMapping("/admin/meter-readings/{id}/cancel")
    public ApiResponse<MeterReading> cancelReading(@PathVariable Long id) {
        return ApiResponse.success(billing.cancelReading(id));
    }

    @PostMapping("/admin/invoices/generate-draft")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Invoice> generate(@Valid @RequestBody GenerateInvoiceRequest request) {
        return ApiResponse.success("Created", billing.generateInvoice(request));
    }

    @PostMapping("/admin/invoices/generate-monthly")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<java.util.List<Invoice>> generateMonthly(@Valid @RequestBody GenerateMonthlyInvoicesRequest request) {
        return ApiResponse.success("Created", billing.generateMonthly(request));
    }

    @GetMapping("/admin/invoices")
    public ApiResponse<PageResponse<Invoice>> invoices(@RequestParam(required = false) InvoiceStatus status,
                                                       @RequestParam(required = false) Integer month,
                                                       @RequestParam(required = false) Integer year,
                                                       @RequestParam(required = false) Long tenantId,
                                                       Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.invoices(status, month, year, tenantId, pageable)));
    }

    @GetMapping("/admin/invoices/{id}")
    public ApiResponse<InvoiceDetail> invoice(@PathVariable Long id) {
        return ApiResponse.success(billing.invoiceDetail(id));
    }

    @PostMapping("/admin/invoices/{id}/items/adjustment")
    public ApiResponse<Invoice> adjustment(@PathVariable Long id, @Valid @RequestBody InvoiceAdjustmentRequest request) {
        return ApiResponse.success(billing.addAdjustment(id, request));
    }

    @PutMapping("/admin/invoices/{id}/items")
    public ApiResponse<Invoice> updateItems(@PathVariable Long id, @Valid @RequestBody InvoiceItemsUpdateRequest request) {
        return ApiResponse.success(billing.updateItems(id, request));
    }

    @PutMapping("/admin/invoices/{id}/issue")
    public ApiResponse<Invoice> issue(@PathVariable Long id, @Valid @RequestBody InvoiceIssueRequest request) {
        return ApiResponse.success(billing.issue(id, request));
    }

    @PutMapping("/admin/invoices/{id}/cancel")
    public ApiResponse<Invoice> cancel(@PathVariable Long id, @RequestBody(required = false) InvoiceCancelRequest request) {
        return ApiResponse.success(billing.cancel(id, request));
    }

    @PostMapping("/admin/invoices/{invoiceId}/payments")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Payment> payment(@PathVariable Long invoiceId, @Valid @RequestBody PaymentCreateRequest request) {
        return ApiResponse.success("Created", billing.recordPayment(invoiceId, request));
    }

    @GetMapping("/admin/payments")
    public ApiResponse<PageResponse<Payment>> payments(@RequestParam(required = false) Long invoiceId,
                                                @RequestParam(required = false) PaymentStatus status,
                                                Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.payments(invoiceId, status, pageable)));
    }

    @GetMapping("/admin/payments/{id}")
    public ApiResponse<Payment> payment(@PathVariable Long id) {
        return ApiResponse.success(billing.payment(id));
    }

    @PutMapping("/admin/payments/{id}/cancel")
    public ApiResponse<Payment> cancelPayment(@PathVariable Long id, @Valid @RequestBody PaymentCancelRequest request) {
        return ApiResponse.success(billing.cancelPayment(id, request));
    }

    @GetMapping("/admin/debts")
    public ApiResponse<PageResponse<Invoice>> debts(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.debts(pageable)));
    }

    @GetMapping("/tenant/invoices")
    public ApiResponse<PageResponse<Invoice>> tenantInvoices(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.tenantInvoices(pageable)));
    }

    @GetMapping("/tenant/invoices/{id}")
    public ApiResponse<InvoiceDetail> tenantInvoice(@PathVariable Long id) {
        return ApiResponse.success(billing.tenantInvoice(id));
    }

    @GetMapping("/tenant/payments")
    public ApiResponse<PageResponse<Payment>> tenantPayments(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.tenantPayments(pageable)));
    }

    @GetMapping("/tenant/meter-readings")
    public ApiResponse<PageResponse<MeterReading>> tenantReadings(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.tenantReadings(pageable)));
    }

    @GetMapping("/tenant/debt")
    public ApiResponse<PageResponse<Invoice>> tenantDebt(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(billing.tenantDebtInvoices(pageable)));
    }
}
