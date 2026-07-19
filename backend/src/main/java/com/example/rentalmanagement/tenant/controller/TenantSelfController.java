package com.example.rentalmanagement.tenant.controller;

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
import com.example.rentalmanagement.tenant.service.TenantProfileSelfService;
import com.example.rentalmanagement.user.*;
import com.example.rentalmanagement.user.dto.*;
import com.example.rentalmanagement.user.repository.*;

@RestController
@RequestMapping("/api/v1/tenant")
public class TenantSelfController {
    private final PropertyService property;
    private final ContractManagementService contracts;
    private final CurrentUser currentUser;
    private final TenantProfileSelfService profileService;

    public TenantSelfController(PropertyService property, ContractManagementService contracts, CurrentUser currentUser, TenantProfileSelfService profileService) {
        this.property = property;
        this.contracts = contracts;
        this.currentUser = currentUser;
        this.profileService = profileService;
    }

    @GetMapping("/profile")
    public ApiResponse<TenantProfile> profile() {
        return ApiResponse.success(property.tenantProfileForUser(currentUser.userId()));
    }

    @PatchMapping("/profile")
    public ApiResponse<UserResponse> updateProfile(@Valid @RequestBody TenantSelfProfileUpdateRequest request) {
        return ApiResponse.success("Profile updated", profileService.updateProfile(currentUser.userId(), request));
    }

    @PostMapping("/profile/email/request")
    public ApiResponse<EmailChangeStartResponse> requestEmailChange(@Valid @RequestBody EmailChangeRequest request) {
        return ApiResponse.success(profileService.requestEmailChange(currentUser.userId(), request));
    }

    @PostMapping("/profile/email/verify")
    public ApiResponse<UserResponse> verifyEmailChange(@Valid @RequestBody EmailChangeVerifyRequest request) {
        return ApiResponse.success("Email updated", profileService.verifyEmailChange(currentUser.userId(), request));
    }

    @GetMapping("/contracts/current")
    public ApiResponse<RentalContract> currentContract() {
        return ApiResponse.success(contracts.tenantCurrentContract(currentUser.userId()));
    }

    @PutMapping("/contracts/{id}/confirm")
    public ApiResponse<RentalContract> confirmContract(@PathVariable Long id) {
        return ApiResponse.success(
                "Contract confirmed",
                contracts.confirmByTenant(currentUser.userId(), id)
        );
    }

    @PutMapping("/contracts/{id}/reject")
    public ApiResponse<RentalContract> rejectContract(
            @PathVariable Long id,
            @Valid @RequestBody ContractRejectionRequest request
    ) {
        return ApiResponse.success(
                "Contract rejected",
                contracts.rejectByTenant(currentUser.userId(), id, request)
        );
    }

    @GetMapping("/contracts/history")
    public ApiResponse<PageResponse<RentalContract>> contractHistory(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(contracts.tenantContractHistory(currentUser.userId(), pageable)));
    }
}
