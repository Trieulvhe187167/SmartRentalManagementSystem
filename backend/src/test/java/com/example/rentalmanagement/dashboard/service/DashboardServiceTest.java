package com.example.rentalmanagement.dashboard.service;

import com.example.rentalmanagement.common.enums.InvoiceStatus;
import com.example.rentalmanagement.common.enums.RoomStatus;
import com.example.rentalmanagement.common.exception.BusinessException;
import com.example.rentalmanagement.common.security.CurrentUser;
import com.example.rentalmanagement.contract.repository.RentalContractRepository;
import com.example.rentalmanagement.dashboard.dto.AdminDashboardResponse;
import com.example.rentalmanagement.dashboard.dto.MonthlyRevenueResponse;
import com.example.rentalmanagement.invoice.Invoice;
import com.example.rentalmanagement.invoice.repository.InvoiceRepository;
import com.example.rentalmanagement.maintenance.repository.MaintenanceRequestRepository;
import com.example.rentalmanagement.notification.repository.NotificationRepository;
import com.example.rentalmanagement.room.repository.RoomRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {
    @Mock RoomRepository rooms;
    @Mock InvoiceRepository invoices;
    @Mock MaintenanceRequestRepository maintenance;
    @Mock RentalContractRepository contracts;
    @Mock CurrentUser currentUser;
    @Mock NotificationRepository notifications;

    private DashboardService dashboardService;

    @BeforeEach
    void setUp() {
        dashboardService = new DashboardService(
                rooms,
                invoices,
                maintenance,
                contracts,
                currentUser,
                notifications
        );
    }

    @Test
    void monthlyRevenueExcludesDraftAndDebtFromOtherMonths() {
        when(rooms.countByIsDeletedFalse()).thenReturn(0L);
        when(rooms.countByStatusAndIsDeletedFalse(any(RoomStatus.class))).thenReturn(0L);
        when(maintenance.countByStatusInAndIsDeletedFalse(anyList())).thenReturn(0L);
        when(contracts.findByStatusAndEndDateBetweenAndIsDeletedFalse(any(), any(), any()))
                .thenReturn(List.of());

        LocalDate now = LocalDate.now();
        Invoice draft = invoice(now.getMonthValue(), now.getYear(), InvoiceStatus.DRAFT, "1000", "0");
        Invoice issued = invoice(now.getMonthValue(), now.getYear(), InvoiceStatus.ISSUED, "2000", "500");
        Invoice paid = invoice(now.getMonthValue(), now.getYear(), InvoiceStatus.PAID, "3000", "3000");
        Invoice oldOverdue = invoice(
                now.minusMonths(1).getMonthValue(),
                now.minusMonths(1).getYear(),
                InvoiceStatus.OVERDUE,
                "1000",
                "300"
        );
        when(invoices.findAll()).thenReturn(List.of(draft, issued, paid, oldOverdue));

        AdminDashboardResponse result = dashboardService.adminSummary();

        assertEquals(new BigDecimal("5000"), result.monthlyInvoiceAmount());
        assertEquals(new BigDecimal("3500"), result.monthlyCollectedAmount());
        assertEquals(new BigDecimal("1500"), result.monthlyDebtAmount());
        assertEquals(new BigDecimal("2200"), result.totalDebt());
    }

    @Test
    void revenueReportReturnsBilledCollectedDebtAndRealInvoiceCounts() {
        Invoice issued = invoice(7, 2026, InvoiceStatus.ISSUED, "2000", "500");
        Invoice paid = invoice(7, 2026, InvoiceStatus.PAID, "3000", "3000");
        Invoice draft = invoice(7, 2026, InvoiceStatus.DRAFT, "9000", "0");
        when(invoices.findAll()).thenReturn(List.of(issued, paid, draft));

        List<MonthlyRevenueResponse> result = dashboardService.revenueSummary(2026);

        MonthlyRevenueResponse july = result.get(6);
        assertEquals(new BigDecimal("5000"), july.totalRevenue());
        assertEquals(new BigDecimal("3500"), july.collectedRevenue());
        assertEquals(new BigDecimal("1500"), july.debtAmount());
        assertEquals(2, july.invoiceCount());
        assertEquals(1, july.paidInvoiceCount());
    }

    @Test
    void revenueReportRejectsAnInvalidYear() {
        assertThrows(
                BusinessException.class,
                () -> dashboardService.revenueSummary(1999)
        );
    }

    private Invoice invoice(int month, int year, InvoiceStatus status, String total, String paid) {
        Invoice invoice = new Invoice();
        invoice.billingMonth = month;
        invoice.billingYear = year;
        invoice.status = status;
        invoice.totalAmount = new BigDecimal(total);
        invoice.paidAmount = new BigDecimal(paid);
        return invoice;
    }
}
