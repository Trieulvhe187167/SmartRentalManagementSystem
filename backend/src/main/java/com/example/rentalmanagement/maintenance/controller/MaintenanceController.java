package com.example.rentalmanagement.maintenance.controller;

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
public class MaintenanceController {
    private final MaintenanceService maintenance;

    public MaintenanceController(MaintenanceService maintenance) {
        this.maintenance = maintenance;
    }

    @PostMapping("/tenant/maintenance-requests")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MaintenanceRequestEntity> create(@Valid @RequestBody MaintenanceRequestCreateRequest request) {
        return ApiResponse.success("Created", maintenance.create(request));
    }

    @GetMapping("/tenant/maintenance-requests")
    public ApiResponse<PageResponse<MaintenanceRequestEntity>> tenantRequests(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(maintenance.tenantRequests(pageable)));
    }

    @GetMapping("/tenant/maintenance-requests/{id}")
    public ApiResponse<MaintenanceRequestEntity> tenantRequest(@PathVariable Long id) {
        return ApiResponse.success(maintenance.tenantRequest(id));
    }

    @PutMapping("/tenant/maintenance-requests/{id}")
    public ApiResponse<MaintenanceRequestEntity> updateTenantRequest(@PathVariable Long id, @Valid @RequestBody MaintenanceRequestUpdateRequest request) {
        return ApiResponse.success(maintenance.updateTenantRequest(id, request));
    }

    @PutMapping("/tenant/maintenance-requests/{id}/cancel")
    public ApiResponse<MaintenanceRequestEntity> cancel(@PathVariable Long id) {
        return ApiResponse.success(maintenance.cancelTenant(id));
    }

    @GetMapping("/admin/maintenance-requests")
    public ApiResponse<PageResponse<MaintenanceRequestEntity>> adminRequests(@RequestParam(required = false) MaintenanceStatus status, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(maintenance.adminRequests(status, pageable)));
    }

    @GetMapping("/admin/maintenance-requests/{id}")
    public ApiResponse<MaintenanceRequestEntity> adminRequest(@PathVariable Long id) {
        return ApiResponse.success(maintenance.adminRequest(id));
    }

    @GetMapping("/admin/maintenance-requests/{id}/updates")
    public ApiResponse<PageResponse<MaintenanceUpdate>> updates(@PathVariable Long id, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(maintenance.updates(id, pageable)));
    }

    @PutMapping("/admin/maintenance-requests/{id}/receive")
    public ApiResponse<MaintenanceRequestEntity> receive(@PathVariable Long id, @Valid @RequestBody MaintenanceStatusUpdateRequest request) {
        return ApiResponse.success(maintenance.updateStatus(id, MaintenanceStatus.RECEIVED, request));
    }

    @PutMapping("/admin/maintenance-requests/{id}/in-progress")
    public ApiResponse<MaintenanceRequestEntity> progress(@PathVariable Long id, @Valid @RequestBody MaintenanceStatusUpdateRequest request) {
        return ApiResponse.success(maintenance.updateStatus(id, MaintenanceStatus.IN_PROGRESS, request));
    }

    @PutMapping("/admin/maintenance-requests/{id}/resolve")
    public ApiResponse<MaintenanceRequestEntity> resolve(@PathVariable Long id, @Valid @RequestBody MaintenanceStatusUpdateRequest request) {
        return ApiResponse.success(maintenance.updateStatus(id, MaintenanceStatus.RESOLVED, request));
    }

    @PutMapping("/admin/maintenance-requests/{id}/reject")
    public ApiResponse<MaintenanceRequestEntity> reject(@PathVariable Long id, @Valid @RequestBody MaintenanceStatusUpdateRequest request) {
        return ApiResponse.success(maintenance.updateStatus(id, MaintenanceStatus.REJECTED, request));
    }
}
