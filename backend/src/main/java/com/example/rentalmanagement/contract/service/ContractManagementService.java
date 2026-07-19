package com.example.rentalmanagement.contract.service;

import java.nio.charset.*;
import com.example.rentalmanagement.common.scheduling.*;

import java.math.*;
import java.time.*;
import java.util.*;
import java.text.Normalizer;
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

@Service
public class ContractManagementService {
    private final RentalContractRepository contracts;
    private final RoomRepository rooms;
    private final TenantProfileRepository tenants;
    private final OccupantRepository occupants;
    private final ContractOccupantRepository contractOccupants;
    private final ServiceItemRepository services;
    private final ServicePriceRepository prices;
    private final ContractServiceRepository contractServices;

    public ContractManagementService(RentalContractRepository contracts, RoomRepository rooms, TenantProfileRepository tenants, OccupantRepository occupants, ContractOccupantRepository contractOccupants, ServiceItemRepository services, ServicePriceRepository prices, ContractServiceRepository contractServices) {
        this.contracts = contracts;
        this.rooms = rooms;
        this.tenants = tenants;
        this.occupants = occupants;
        this.contractOccupants = contractOccupants;
        this.services = services;
        this.prices = prices;
        this.contractServices = contractServices;
    }

    @Transactional
    public RentalContract createContract(ContractCreateRequest request) {
        if (!request.endDate().isAfter(request.startDate())) {
            throw new BusinessException("Contract end date must be after start date", "CONTRACT_INVALID_DATE", HttpStatus.BAD_REQUEST);
        }
        if (contracts.existsByContractCode(request.contractCode())) {
            throw new BusinessException("Contract code already exists", "CONTRACT_CODE_EXISTS");
        }
        Room room = rooms.findById(request.roomId()).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        TenantProfile tenant = tenants.findById(request.primaryTenantId()).orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND"));
        requireTenantAvailableForNewContract(tenant.id, null);
        if (room.status != RoomStatus.AVAILABLE) {
            throw new BusinessException("Room is not available for a new contract", "ROOM_NOT_AVAILABLE", HttpStatus.CONFLICT);
        }
        if (contracts.existsByRoomIdAndStatusAndIsDeletedFalse(room.id, ContractStatus.ACTIVE)
                || contracts.existsByRoomIdAndStatusAndIsDeletedFalse(room.id, ContractStatus.PENDING_CONFIRMATION)) {
            throw new BusinessException(
                    "Room already has an active contract or one awaiting confirmation",
                    "CONTRACT_ROOM_UNAVAILABLE",
                    HttpStatus.CONFLICT
            );
        }
        RentalContract c = new RentalContract();
        c.contractCode = request.contractCode();
        c.room = room;
        c.primaryTenant = tenant;
        c.startDate = request.startDate();
        c.endDate = request.endDate();
        c.appliedRent = request.appliedRent();
        c.depositAmount = request.depositAmount();
        c.monthlyDueDay = request.monthlyDueDay();
        c.terms = request.terms();
        c.status = ContractStatus.PENDING_CONFIRMATION;
        return contracts.save(c);
    }

    @Transactional
    public RentalContract updateDraftContract(Long id, ContractCreateRequest request) {
        RentalContract c = contract(id);
        if (c.status != ContractStatus.DRAFT && c.status != ContractStatus.PENDING_CONFIRMATION) {
            throw new BusinessException("Only a contract awaiting confirmation can be updated", "CONTRACT_NOT_EDITABLE");
        }
        if (!request.endDate().isAfter(request.startDate())) {
            throw new BusinessException("Contract end date must be after start date", "CONTRACT_INVALID_DATE", HttpStatus.BAD_REQUEST);
        }
        Room room = rooms.findById(request.roomId()).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        TenantProfile tenant = tenants.findById(request.primaryTenantId()).orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND"));
        requireTenantAvailableForNewContract(tenant.id, c.id);
        c.contractCode = request.contractCode();
        c.room = room;
        c.primaryTenant = tenant;
        c.startDate = request.startDate();
        c.endDate = request.endDate();
        c.appliedRent = request.appliedRent();
        c.depositAmount = request.depositAmount();
        c.monthlyDueDay = request.monthlyDueDay();
        c.terms = request.terms();
        return c;
    }

    public Page<RentalContract> search(ContractStatus status, Long roomId, Long tenantId, Pageable pageable) {
        return contracts.search(status, roomId, tenantId, pageable).map(this::withOccupancy);
    }

    public RentalContract contract(Long id) {
        return withOccupancy(contracts.findById(id).orElseThrow(() -> new NotFoundException("Contract not found", "CONTRACT_NOT_FOUND")));
    }

    @Transactional
    public ContractOccupant addOccupant(Long contractId, ContractOccupantRequest request) {
        RentalContract contract = contract(contractId);
        Occupant occupant = occupants.findById(request.occupantId()).orElseThrow(() -> new NotFoundException("Occupant not found", "OCCUPANT_NOT_FOUND"));
        long residents = 1 + contractOccupants.countActiveOnDate(contractId, request.moveInDate());
        if (residents + 1 > contract.room.maxOccupants) {
            throw new BusinessException("Room resident count exceeds capacity", "CAPACITY_EXCEEDED");
        }
        ContractOccupant co = new ContractOccupant();
        co.contract = contract;
        co.occupant = occupant;
        co.relationshipToPrimary = request.relationshipToPrimary();
        co.moveInDate = request.moveInDate();
        return contractOccupants.save(co);
    }

    @Transactional
    public ContractOccupant createAndAddOccupant(Long contractId, ContractOccupantCreateRequest request) {
        Occupant occupant = new Occupant();
        occupant.fullName = request.fullName().trim();
        occupant.dateOfBirth = request.dateOfBirth();
        occupant.phone = request.phone();
        occupant.identityType = request.identityType();
        occupant.identityNumber = request.identityNumber();
        occupant.permanentAddress = request.permanentAddress();
        occupant.status = RecordStatus.ACTIVE;
        Occupant saved = occupants.save(occupant);
        return addOccupant(
                contractId,
                new ContractOccupantRequest(saved.id, request.relationshipToPrimary(), request.moveInDate())
        );
    }

    public List<ContractOccupant> contractOccupantList(Long contractId) {
        contract(contractId);
        return contractOccupants.findByContractIdAndIsDeletedFalseOrderByMoveInDateAsc(contractId);
    }

    @Transactional
    public ContractOccupant removeOrMoveOutOccupant(Long contractId, Long occupantId) {
        ContractOccupant co = contractOccupants.findByContractIdAndOccupantIdAndIsDeletedFalse(contractId, occupantId)
                .orElseThrow(() -> new NotFoundException("Contract occupant not found", "CONTRACT_OCCUPANT_NOT_FOUND"));
        if (co.contract.status == ContractStatus.DRAFT
                || co.contract.status == ContractStatus.PENDING_CONFIRMATION) {
            co.isDeleted = true;
            co.deletedAt = LocalDateTime.now();
        } else {
            co.moveOutDate = LocalDate.now();
        }
        return co;
    }

    @Transactional
    public ContractOccupant moveOutOccupant(Long contractId, Long occupantId) {
        ContractOccupant co = contractOccupants.findByContractIdAndOccupantIdAndIsDeletedFalse(contractId, occupantId)
                .orElseThrow(() -> new NotFoundException("Contract occupant not found", "CONTRACT_OCCUPANT_NOT_FOUND"));
        co.moveOutDate = LocalDate.now();
        return co;
    }

    @Transactional
    public RentalContract activate(Long id) {
        RentalContract contract = contract(id);
        if (contract.status == ContractStatus.ACTIVE) {
            return contract;
        }
        throw new BusinessException(
                "Tenant confirmation is required before contract activation",
                "TENANT_CONFIRMATION_REQUIRED",
                HttpStatus.CONFLICT
        );
    }

    @Transactional
    public RentalContract terminate(Long id, ContractTerminateRequest request) {
        RentalContract contract = contract(id);
        contract.status = ContractStatus.TERMINATED;
        contract.endedAt = LocalDateTime.now();
        contract.terminationReason = request.reason();
        return contract;
    }

    @Transactional
    public RentalContract expire(Long id) {
        RentalContract contract = contract(id);
        contract.status = ContractStatus.EXPIRED;
        contract.endedAt = LocalDateTime.now();
        return contract;
    }

    @Transactional
    public RentalContract renew(Long id, ContractRenewRequest request) {
        RentalContract current = contract(id);
        RentalContract renewed = new RentalContract();
        renewed.contractCode = current.contractCode + "-R" + System.currentTimeMillis();
        renewed.room = current.room;
        renewed.primaryTenant = current.primaryTenant;
        renewed.renewedFromContract = current;
        renewed.startDate = current.endDate.plusDays(1);
        renewed.endDate = request.endDate();
        renewed.appliedRent = request.appliedRent();
        renewed.depositAmount = request.depositAmount();
        renewed.monthlyDueDay = request.monthlyDueDay();
        renewed.terms = request.terms();
        renewed.status = ContractStatus.PENDING_CONFIRMATION;
        return contracts.save(renewed);
    }

    @Transactional
    public ServiceItem saveService(ServiceRequest request, Long id) {
        if ((request.initialUnitPrice() == null) != (request.priceEffectiveFrom() == null)) {
            throw new BusinessException(
                    "Initial price and effective date must be provided together",
                    "SERVICE_INITIAL_PRICE_INCOMPLETE",
                    HttpStatus.BAD_REQUEST
            );
        }
        ServiceItem service = id == null ? new ServiceItem() : services.findById(id).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        String code = normalizeServiceCode(request.code(), request.name());
        if (id == null && services.existsByCode(code) && isServiceTypeCode(code)) {
            code = normalizeServiceCode(code + "_" + request.name(), request.name());
        }
        if (id == null && services.existsByCode(code)) {
            throw new BusinessException("Service code already exists", "SERVICE_CODE_EXISTS");
        }
        if (id != null && !service.code.equals(code) && services.existsByCode(code)) {
            throw new BusinessException("Service code already exists", "SERVICE_CODE_EXISTS");
        }
        service.code = code;
        service.name = request.name();
        service.unit = request.unit();
        service.chargeType = request.chargeType();
        service.description = request.description();
        service.status = request.active() == null || request.active() ? RecordStatus.ACTIVE : RecordStatus.INACTIVE;
        ServiceItem saved = services.save(service);
        if (id == null && request.initialUnitPrice() != null) {
            addPrice(new ServicePriceRequest(
                    saved.id,
                    request.initialUnitPrice(),
                    request.priceEffectiveFrom(),
                    null,
                    "Giá ban đầu khi tạo dịch vụ"
            ));
        }
        return enrichService(saved);
    }

    public Page<ServiceItem> services(Pageable pageable) {
        return services.search(null, pageable).map(this::enrichService);
    }

    public ServiceItem service(Long id) {
        return enrichService(services.findById(id).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND")));
    }

    @Transactional
    public ServiceItem inactiveService(Long id) {
        return setServiceActive(id, false);
    }

    @Transactional
    public ServiceItem setServiceActive(Long id, boolean active) {
        ServiceItem service = service(id);
        service.status = active ? RecordStatus.ACTIVE : RecordStatus.INACTIVE;
        return service;
    }

    @Transactional
    public ServicePrice addPrice(ServicePriceRequest request) {
        if (request.serviceId() == null) {
            throw new BusinessException("serviceId is required", "SERVICE_ID_REQUIRED", HttpStatus.BAD_REQUEST);
        }
        ServiceItem service = services.findById(request.serviceId()).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        LocalDate effectiveTo = request.effectiveTo() == null ? LocalDate.of(9999, 12, 31) : request.effectiveTo();
        if (request.effectiveTo() != null && request.effectiveTo().isBefore(request.effectiveFrom())) {
            throw new BusinessException("Price effectiveTo must not be before effectiveFrom", "SERVICE_PRICE_INVALID_DATE");
        }
        List<ServicePrice> effectivePrices = prices.findEffective(service.id, request.effectiveFrom());
        Optional<ServicePrice> sameDatePrice = effectivePrices.stream()
                .filter(existing -> existing.effectiveFrom.equals(request.effectiveFrom()))
                .findFirst();
        if (sameDatePrice.isPresent()) {
            ServicePrice price = sameDatePrice.get();
            price.unitPrice = request.unitPrice();
            price.effectiveTo = request.effectiveTo();
            price.notes = request.notes();
            return prices.saveAndFlush(price);
        }
        effectivePrices.stream()
                .filter(existing -> existing.effectiveTo == null || !existing.effectiveTo.isBefore(request.effectiveFrom()))
                .forEach(existing -> {
                    if (existing.effectiveFrom.isBefore(request.effectiveFrom())) {
                        existing.effectiveTo = request.effectiveFrom().minusDays(1);
                    } else {
                        existing.isDeleted = true;
                    }
                });
        prices.flush();
        ServicePrice price = new ServicePrice();
        price.serviceItem = service;
        price.unitPrice = request.unitPrice();
        price.effectiveFrom = request.effectiveFrom();
        price.effectiveTo = request.effectiveTo();
        price.notes = request.notes();
        return prices.saveAndFlush(price);
    }

    private ServiceItem enrichService(ServiceItem service) {
        service.currentPrice = prices.findEffective(service.id, LocalDate.now()).stream()
                .findFirst()
                .map(price -> price.unitPrice)
                .orElse(null);
        return service;
    }

    private String normalizeServiceCode(String code, String name) {
        String source = code == null || code.isBlank() ? name : code;
        String asciiSource = Normalizer.normalize(source, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .replace('Đ', 'D')
                .replace('đ', 'd');
        String normalized = asciiSource.trim().toUpperCase()
                .replaceAll("[^A-Z0-9]+", "_")
                .replaceAll("^_+|_+$", "");
        if (normalized.isBlank()) {
            throw new BusinessException("Service code is required", "SERVICE_CODE_REQUIRED", HttpStatus.BAD_REQUEST);
        }
        return normalized;
    }

    private boolean isServiceTypeCode(String code) {
        return Set.of("ELECTRICITY", "WATER", "INTERNET", "CLEANING", "PARKING", "OTHER").contains(code);
    }

    public Page<ServicePrice> servicePrices(Long serviceId, Pageable pageable) {
        return prices.findByServiceItemIdAndIsDeletedFalse(serviceId, pageable);
    }

    @Transactional
    public ServicePrice updatePrice(Long id, ServicePriceRequest request) {
        ServicePrice price = prices.findById(id).orElseThrow(() -> new NotFoundException("Service price not found", "SERVICE_PRICE_NOT_FOUND"));
        ServiceItem service = request.serviceId() == null ? price.serviceItem : services.findById(request.serviceId()).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        if (request.effectiveTo() != null && request.effectiveTo().isBefore(request.effectiveFrom())) {
            throw new BusinessException("Price effectiveTo must not be before effectiveFrom", "SERVICE_PRICE_INVALID_DATE");
        }
        price.serviceItem = service;
        price.unitPrice = request.unitPrice();
        price.effectiveFrom = request.effectiveFrom();
        price.effectiveTo = request.effectiveTo();
        price.notes = request.notes();
        return price;
    }

    @Transactional
    public ContractService saveContractService(ContractServiceRequest request) {
        ContractService cs = new ContractService();
        cs.contract = contract(request.contractId());
        cs.serviceItem = services.findById(request.serviceId()).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        cs.startDate = request.startDate();
        cs.endDate = request.endDate();
        cs.status = request.active() == null || request.active() ? RecordStatus.ACTIVE : RecordStatus.INACTIVE;
        cs.notes = request.notes();
        return contractServices.save(cs);
    }

    @Transactional
    public ContractService saveContractService(Long contractId, ContractServiceAssignRequest request) {
        return saveContractService(new ContractServiceRequest(contractId, request.serviceId(), request.startDate(), request.endDate(), request.active(), request.notes()));
    }

    @Transactional
    public ContractService inactiveContractService(Long id) {
        ContractService cs = contractServices.findById(id).orElseThrow(() -> new NotFoundException("Contract service not found", "CONTRACT_SERVICE_NOT_FOUND"));
        cs.status = RecordStatus.INACTIVE;
        cs.endDate = cs.endDate == null ? LocalDate.now() : cs.endDate;
        return cs;
    }

    public Page<ContractService> contractServices(Long contractId, Pageable pageable) {
        return contractServices.findByContractIdAndIsDeletedFalse(contractId, pageable);
    }

    public Page<RentalContract> tenantContracts(Long tenantId, Pageable pageable) {
        return contracts.findByPrimaryTenantIdAndIsDeletedFalse(tenantId, pageable).map(this::withOccupancy);
    }

    public RentalContract tenantCurrentContract(Long userId) {
        return contracts.findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalseOrderByCreatedAtDesc(
                        userId,
                        ContractStatus.PENDING_CONFIRMATION
                )
                .or(() -> contracts.findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalseOrderByCreatedAtDesc(
                        userId,
                        ContractStatus.ACTIVE
                ))
                .map(this::withOccupancy)
                .orElse(null);
    }

    @Transactional
    public RentalContract confirmByTenant(Long userId, Long contractId) {
        RentalContract contract = tenantContract(userId, contractId);
        requirePendingConfirmation(contract);
        if (contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalse(
                contract.primaryTenant.id,
                ContractStatus.ACTIVE
        )) {
            throw new BusinessException(
                    "Khách thuê đã có một hợp đồng đang hiệu lực",
                    "TENANT_ACTIVE_CONTRACT_EXISTS",
                    HttpStatus.CONFLICT
            );
        }
        if (contract.room.status != RoomStatus.AVAILABLE) {
            throw new BusinessException("Room is no longer available", "ROOM_NOT_AVAILABLE", HttpStatus.CONFLICT);
        }
        if (contracts.existsByRoomIdAndStatusAndIsDeletedFalse(contract.room.id, ContractStatus.ACTIVE)) {
            throw new BusinessException("Room already has an active contract", "CONTRACT_ACTIVE_EXISTS", HttpStatus.CONFLICT);
        }

        LocalDateTime now = LocalDateTime.now();
        contract.status = ContractStatus.ACTIVE;
        contract.tenantConfirmedAt = now;
        contract.activatedAt = now;
        contract.room.status = RoomStatus.OCCUPIED;
        return contract;
    }

    private void requireTenantAvailableForNewContract(Long tenantId, Long excludedContractId) {
        boolean hasActiveContract;
        boolean hasPendingContract;
        if (excludedContractId == null) {
            hasActiveContract = contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalse(
                    tenantId,
                    ContractStatus.ACTIVE
            );
            hasPendingContract = contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalse(
                    tenantId,
                    ContractStatus.PENDING_CONFIRMATION
            );
        } else {
            hasActiveContract = contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalseAndIdNot(
                    tenantId,
                    ContractStatus.ACTIVE,
                    excludedContractId
            );
            hasPendingContract = contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalseAndIdNot(
                    tenantId,
                    ContractStatus.PENDING_CONFIRMATION,
                    excludedContractId
            );
        }

        if (hasActiveContract) {
            throw new BusinessException(
                    "Khách thuê đã có một hợp đồng đang hiệu lực",
                    "TENANT_ACTIVE_CONTRACT_EXISTS",
                    HttpStatus.CONFLICT
            );
        }
        if (hasPendingContract) {
            throw new BusinessException(
                    "Khách thuê đã có một hợp đồng đang chờ xác nhận",
                    "TENANT_PENDING_CONTRACT_EXISTS",
                    HttpStatus.CONFLICT
            );
        }
    }

    @Transactional
    public RentalContract rejectByTenant(Long userId, Long contractId, ContractRejectionRequest request) {
        RentalContract contract = tenantContract(userId, contractId);
        requirePendingConfirmation(contract);
        contract.status = ContractStatus.REJECTED;
        contract.tenantRejectedAt = LocalDateTime.now();
        contract.tenantRejectionReason = request.reason().trim();
        return contract;
    }

    private RentalContract tenantContract(Long userId, Long contractId) {
        return contracts.findByIdAndPrimaryTenantUserIdAndIsDeletedFalse(contractId, userId)
                .orElseThrow(() -> new NotFoundException("Contract not found", "CONTRACT_NOT_FOUND"));
    }

    private void requirePendingConfirmation(RentalContract contract) {
        if (contract.status != ContractStatus.PENDING_CONFIRMATION) {
            throw new BusinessException(
                    "Contract is not awaiting tenant confirmation",
                    "CONTRACT_NOT_PENDING_CONFIRMATION",
                    HttpStatus.CONFLICT
            );
        }
    }

    public Page<RentalContract> tenantContractHistory(Long userId, Pageable pageable) {
        return contracts.findByPrimaryTenantUserIdAndIsDeletedFalse(userId, pageable).map(this::withOccupancy);
    }

    private RentalContract withOccupancy(RentalContract contract) {
        contract.currentOccupantCount = 1 + contractOccupants.countActiveOnDate(contract.id, LocalDate.now());
        return contract;
    }
}
