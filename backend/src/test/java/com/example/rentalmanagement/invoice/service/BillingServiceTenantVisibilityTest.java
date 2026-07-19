package com.example.rentalmanagement.invoice.service;

import com.example.rentalmanagement.common.enums.InvoiceStatus;
import com.example.rentalmanagement.common.exception.NotFoundException;
import com.example.rentalmanagement.common.security.CurrentUser;
import com.example.rentalmanagement.contract.repository.ContractOccupantRepository;
import com.example.rentalmanagement.contract.repository.ContractServiceRepository;
import com.example.rentalmanagement.contract.repository.RentalContractRepository;
import com.example.rentalmanagement.invoice.Invoice;
import com.example.rentalmanagement.invoice.repository.DatabaseProcedureRepository;
import com.example.rentalmanagement.invoice.repository.InvoiceItemRepository;
import com.example.rentalmanagement.invoice.repository.InvoiceRepository;
import com.example.rentalmanagement.meterreading.repository.MeterReadingRepository;
import com.example.rentalmanagement.notification.service.NotificationService;
import com.example.rentalmanagement.payment.repository.PaymentRepository;
import com.example.rentalmanagement.room.repository.RoomRepository;
import com.example.rentalmanagement.serviceitem.repository.ServiceItemRepository;
import com.example.rentalmanagement.serviceitem.repository.ServicePriceRepository;
import com.example.rentalmanagement.user.repository.UserRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.time.LocalDate;
import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BillingServiceTenantVisibilityTest {
    @Mock RoomRepository rooms;
    @Mock RentalContractRepository contracts;
    @Mock ServiceItemRepository services;
    @Mock ServicePriceRepository prices;
    @Mock ContractServiceRepository contractServices;
    @Mock ContractOccupantRepository contractOccupants;
    @Mock MeterReadingRepository readings;
    @Mock InvoiceRepository invoices;
    @Mock InvoiceItemRepository items;
    @Mock PaymentRepository payments;
    @Mock DatabaseProcedureRepository procedures;
    @Mock NotificationService notifications;
    @Mock CurrentUser currentUser;
    @Mock UserRepository users;
    @Mock EntityManager entityManager;

    private BillingService billingService;

    @BeforeEach
    void setUp() {
        billingService = new BillingService(
                rooms,
                contracts,
                services,
                prices,
                contractServices,
                contractOccupants,
                readings,
                invoices,
                items,
                payments,
                procedures,
                notifications,
                currentUser,
                users,
                entityManager
        );
    }

    @Test
    void tenantInvoiceListQueriesOnlyPublishedStatuses() {
        when(currentUser.userId()).thenReturn(42L);
        Pageable pageable = PageRequest.of(0, 20);
        when(invoices.findByTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                eq(42L),
                org.mockito.ArgumentMatchers.anyCollection(),
                eq(pageable)
        )).thenReturn(new PageImpl<>(List.of()));

        Page<Invoice> result = billingService.tenantInvoices(pageable);

        assertEquals(0, result.getTotalElements());
        verify(invoices).findByTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                eq(42L),
                eq(List.of(
                        InvoiceStatus.ISSUED,
                        InvoiceStatus.PARTIALLY_PAID,
                        InvoiceStatus.PAID,
                        InvoiceStatus.OVERDUE
                )),
                eq(pageable)
        );
    }

    @Test
    void tenantCannotOpenDraftInvoiceById() {
        when(currentUser.userId()).thenReturn(42L);
        when(invoices.findByIdAndTenantProfileUserIdAndStatusInAndIsDeletedFalse(
                eq(99L),
                eq(42L),
                org.mockito.ArgumentMatchers.anyCollection()
        )).thenReturn(Optional.empty());

        assertThrows(NotFoundException.class, () -> billingService.tenantInvoice(99L));
    }

    @Test
    void perPersonQuantityUsesResidentsActiveAtTheStartOfBillingMonth() {
        LocalDate billingDate = LocalDate.of(2026, 7, 1);
        when(contractOccupants.countActiveOnDate(10L, billingDate)).thenReturn(1L);

        BigDecimal quantity = billingService.residentQuantity(10L, billingDate);

        assertEquals(new BigDecimal("2"), quantity);
        verify(contractOccupants).countActiveOnDate(10L, billingDate);
    }
}
