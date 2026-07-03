package com.example.rentalmanagement.user.controller;

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
@RequestMapping("/api/v1/admin/users")
public class AdminUserController {
    private final AuthService auth;

    public AdminUserController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/tenant-accounts")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<UserResponse> createTenant(@Valid @RequestBody CreateTenantAccountRequest request) {
        return ApiResponse.success("Created", auth.createTenantAccount(request));
    }

    @GetMapping
    public ApiResponse<PageResponse<UserResponse>> users(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(auth.users(pageable)));
    }

    @PutMapping("/{id}/lock")
    public ApiResponse<UserResponse> lock(@PathVariable Long id) {
        return ApiResponse.success(auth.lock(id));
    }

    @PutMapping("/{id}/unlock")
    public ApiResponse<UserResponse> unlock(@PathVariable Long id) {
        return ApiResponse.success(auth.unlock(id));
    }

    @PutMapping("/{id}/reset-password")
    public ApiResponse<UserResponse> reset(@PathVariable Long id, @Valid @RequestBody ResetPasswordRequest request) {
        return ApiResponse.success(auth.resetPassword(id, request));
    }
}
