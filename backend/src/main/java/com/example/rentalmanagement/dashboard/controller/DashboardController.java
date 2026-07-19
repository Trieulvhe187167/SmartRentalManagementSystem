package com.example.rentalmanagement.dashboard.controller;

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
public class DashboardController {
    private final DashboardService dashboard;

    public DashboardController(DashboardService dashboard) {
        this.dashboard = dashboard;
    }

    @GetMapping("/admin/dashboard/summary")
    public ApiResponse<AdminDashboardResponse> adminSummary() {
        return ApiResponse.success(dashboard.adminSummary());
    }

    @GetMapping("/admin/dashboard/rooms")
    public ApiResponse<java.util.Map<String, Long>> roomStats() {
        return ApiResponse.success(dashboard.roomStats());
    }

    @GetMapping("/admin/dashboard/revenue")
    public ApiResponse<java.util.List<MonthlyRevenueResponse>> revenue(
            @RequestParam(required = false) Integer year) {
        return ApiResponse.success(dashboard.revenueSummary(year));
    }

    @GetMapping("/admin/dashboard/contracts-expiring")
    public ApiResponse<java.util.List<RentalContract>> expiring() {
        return ApiResponse.success(dashboard.expiringContracts());
    }

    @GetMapping("/admin/dashboard/open-maintenance")
    public ApiResponse<PageResponse<MaintenanceRequestEntity>> maintenance(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(dashboard.openMaintenance(pageable)));
    }

    @GetMapping("/tenant/dashboard")
    public ApiResponse<TenantDashboardResponse> tenantDashboard() {
        return ApiResponse.success(dashboard.tenantSummary());
    }

    @GetMapping("/tenant/current-room")
    public ApiResponse<Room> currentRoom() {
        TenantDashboardResponse data = dashboard.tenantSummary();
        return ApiResponse.success(data.currentRoom());
    }

    @GetMapping("/tenant/current-invoice")
    public ApiResponse<Invoice> currentInvoice() {
        TenantDashboardResponse data = dashboard.tenantSummary();
        return ApiResponse.success(data.latestInvoice());
    }

    @GetMapping("/tenant/current-debt")
    public ApiResponse<java.math.BigDecimal> currentDebt() {
        TenantDashboardResponse data = dashboard.tenantSummary();
        return ApiResponse.success(data.currentDebt());
    }
}
