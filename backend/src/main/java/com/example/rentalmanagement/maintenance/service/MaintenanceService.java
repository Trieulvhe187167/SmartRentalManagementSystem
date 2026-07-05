package com.example.rentalmanagement.maintenance.service;

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
import com.example.rentalmanagement.invoice.service.*;
import com.example.rentalmanagement.maintenance.*;
import com.example.rentalmanagement.maintenance.dto.*;
import com.example.rentalmanagement.maintenance.repository.*;
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
public class MaintenanceService {
    private final MaintenanceRequestRepository requests;
    private final MaintenanceUpdateRepository updates;
    private final RentalContractRepository contracts;
    private final RoomRepository rooms;
    private final CurrentUser currentUser;
    private final NotificationService notifications;

    public MaintenanceService(MaintenanceRequestRepository requests, MaintenanceUpdateRepository updates, RentalContractRepository contracts, RoomRepository rooms, CurrentUser currentUser, NotificationService notifications) {
        this.requests = requests;
        this.updates = updates;
        this.contracts = contracts;
        this.rooms = rooms;
        this.currentUser = currentUser;
        this.notifications = notifications;
    }

    @Transactional
    public MaintenanceRequestEntity create(MaintenanceRequestCreateRequest request) {
        User user = currentUser.requireUser();
        RentalContract contract = request.contractId() == null
                ? contracts.findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalse(user.id, ContractStatus.ACTIVE)
                        .orElseThrow(() -> new BusinessException("Tenant has no active rental contract", "TENANT_ACTIVE_CONTRACT_NOT_FOUND", HttpStatus.BAD_REQUEST))
                : contracts.findById(request.contractId())
                        .orElseThrow(() -> new NotFoundException("Contract not found", "CONTRACT_NOT_FOUND"));
        Room room = request.roomId() == null
                ? contract.room
                : rooms.findById(request.roomId())
                        .orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        if (!contract.primaryTenant.user.id.equals(user.id) || !contract.room.id.equals(room.id) || contract.status != ContractStatus.ACTIVE) {
            throw new BusinessException("Tenant can only create request for current rented room", "ACCESS_DENIED", HttpStatus.FORBIDDEN);
        }
        MaintenanceRequestEntity entity = new MaintenanceRequestEntity();
        entity.requestNumber = "MR-" + System.currentTimeMillis();
        entity.contract = contract;
        entity.room = room;
        entity.requesterUser = user;
        entity.title = request.title();
        entity.description = request.description();
        entity.priority = request.priority();
        entity.status = MaintenanceStatus.OPEN;
        entity.submittedAt = LocalDateTime.now();
        return requests.save(entity);
    }

    public Page<MaintenanceRequestEntity> tenantRequests(Pageable pageable) {
        return requests.findByRequesterUserIdAndIsDeletedFalse(currentUser.userId(), pageable);
    }

    public MaintenanceRequestEntity tenantRequest(Long id) {
        return requests.findByIdAndRequesterUserIdAndIsDeletedFalse(id, currentUser.userId())
                .orElseThrow(() -> new NotFoundException("Maintenance request not found", "MAINTENANCE_NOT_FOUND"));
    }

    @Transactional
    public MaintenanceRequestEntity updateTenantRequest(Long id, MaintenanceRequestUpdateRequest body) {
        MaintenanceRequestEntity request = tenantRequest(id);
        if (request.status != MaintenanceStatus.OPEN) {
            throw new BusinessException("Only OPEN request can be edited", "MAINTENANCE_INVALID_STATUS");
        }
        request.title = body.title();
        request.description = body.description();
        request.priority = body.priority();
        return request;
    }

    @Transactional
    public MaintenanceRequestEntity cancelTenant(Long id) {
        MaintenanceRequestEntity request = tenantRequest(id);
        if (request.status != MaintenanceStatus.OPEN) {
            throw new BusinessException("Only OPEN request can be cancelled", "MAINTENANCE_INVALID_STATUS");
        }
        request.status = MaintenanceStatus.CANCELLED;
        request.cancelledAt = LocalDateTime.now();
        return request;
    }

    public Page<MaintenanceRequestEntity> adminRequests(MaintenanceStatus status, Long tenantId, Pageable pageable) {
        return requests.search(status, tenantId, pageable);
    }

    public MaintenanceRequestEntity adminRequest(Long id) {
        return requests.findById(id).orElseThrow(() -> new NotFoundException("Maintenance request not found", "MAINTENANCE_NOT_FOUND"));
    }

    @Transactional
    public MaintenanceRequestEntity updateStatus(Long id, MaintenanceStatus next, MaintenanceStatusUpdateRequest body) {
        MaintenanceRequestEntity request = requests.findById(id).orElseThrow(() -> new NotFoundException("Maintenance request not found", "MAINTENANCE_NOT_FOUND"));
        if (next == MaintenanceStatus.RESOLVED && (body.resolutionSummary() == null || body.resolutionSummary().isBlank())) {
            throw new BusinessException("Resolution summary is required", "MAINTENANCE_RESOLUTION_REQUIRED");
        }
        if (next == MaintenanceStatus.REJECTED && (body.rejectedReason() == null || body.rejectedReason().isBlank())) {
            throw new BusinessException("Rejected reason is required", "MAINTENANCE_REJECT_REASON_REQUIRED");
        }
        MaintenanceStatus old = request.status;
        request.status = next;
        if (next == MaintenanceStatus.RECEIVED) {
            request.receivedAt = LocalDateTime.now();
        }
        if (next == MaintenanceStatus.RESOLVED) {
            request.resolvedAt = LocalDateTime.now();
            request.resolutionSummary = body.resolutionSummary();
        }
        if (next == MaintenanceStatus.REJECTED) {
            request.rejectedReason = body.rejectedReason();
        }
        MaintenanceUpdate update = new MaintenanceUpdate();
        update.request = request;
        update.oldStatus = old;
        update.newStatus = next;
        update.content = body.content();
        update.createdByUser = currentUser.requireUser();
        updates.save(update);
        notifications.create(request.requesterUser, NotificationType.MAINTENANCE_STATUS_CHANGED, "Maintenance status changed", "Your maintenance request is now " + next + ".");
        return request;
    }

    public Page<MaintenanceUpdate> updates(Long requestId, Pageable pageable) {
        return updates.findByRequestId(requestId, pageable);
    }
}
