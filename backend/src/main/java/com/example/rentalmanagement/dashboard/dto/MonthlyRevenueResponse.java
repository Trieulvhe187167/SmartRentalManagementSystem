package com.example.rentalmanagement.dashboard.dto;

import java.math.BigDecimal;

public record MonthlyRevenueResponse(
        int month,
        int year,
        BigDecimal totalRevenue,
        BigDecimal collectedRevenue,
        BigDecimal debtAmount,
        long invoiceCount,
        long paidInvoiceCount
) {
}
