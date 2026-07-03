package com.example.rentalmanagement.contract.service;

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
        c.status = ContractStatus.DRAFT;
        return contracts.save(c);
    }

    @Transactional
    public RentalContract updateDraftContract(Long id, ContractCreateRequest request) {
        RentalContract c = contract(id);
        if (c.status != ContractStatus.DRAFT) {
            throw new BusinessException("Only DRAFT contract can be updated", "CONTRACT_NOT_EDITABLE");
        }
        if (!request.endDate().isAfter(request.startDate())) {
            throw new BusinessException("Contract end date must be after start date", "CONTRACT_INVALID_DATE", HttpStatus.BAD_REQUEST);
        }
        Room room = rooms.findById(request.roomId()).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        TenantProfile tenant = tenants.findById(request.primaryTenantId()).orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND"));
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
        return contracts.search(status, roomId, tenantId, pageable);
    }

    public RentalContract contract(Long id) {
        return contracts.findById(id).orElseThrow(() -> new NotFoundException("Contract not found", "CONTRACT_NOT_FOUND"));
    }

    @Transactional
    public ContractOccupant addOccupant(Long contractId, ContractOccupantRequest request) {
        RentalContract contract = contract(contractId);
        Occupant occupant = occupants.findById(request.occupantId()).orElseThrow(() -> new NotFoundException("Occupant not found", "OCCUPANT_NOT_FOUND"));
        long residents = 1 + contractOccupants.countByContractIdAndMoveOutDateIsNullAndIsDeletedFalse(contractId);
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
    public ContractOccupant removeOrMoveOutOccupant(Long contractId, Long occupantId) {
        ContractOccupant co = contractOccupants.findByContractIdAndOccupantIdAndIsDeletedFalse(contractId, occupantId)
                .orElseThrow(() -> new NotFoundException("Contract occupant not found", "CONTRACT_OCCUPANT_NOT_FOUND"));
        if (co.contract.status == ContractStatus.DRAFT) {
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
        if (contract.room.status != RoomStatus.AVAILABLE) {
            throw new BusinessException("Room is not available for rent", "ROOM_NOT_AVAILABLE");
        }
        if (contracts.existsByRoomIdAndStatusAndIsDeletedFalse(contract.room.id, ContractStatus.ACTIVE)) {
            throw new BusinessException("Room already has active contract", "CONTRACT_ACTIVE_EXISTS");
        }
        contract.status = ContractStatus.ACTIVE;
        contract.activatedAt = LocalDateTime.now();
        return contract;
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
        renewed.status = ContractStatus.DRAFT;
        return contracts.save(renewed);
    }

    @Transactional
    public ServiceItem saveService(ServiceRequest request, Long id) {
        ServiceItem service = id == null ? new ServiceItem() : services.findById(id).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
        if (id == null && services.existsByCode(request.code())) {
            throw new BusinessException("Service code already exists", "SERVICE_CODE_EXISTS");
        }
        service.code = request.code();
        service.name = request.name();
        service.unit = request.unit();
        service.chargeType = request.chargeType();
        service.description = request.description();
        service.status = request.active() == null || request.active() ? RecordStatus.ACTIVE : RecordStatus.INACTIVE;
        return services.save(service);
    }

    public Page<ServiceItem> services(Pageable pageable) {
        return services.findAll(pageable);
    }

    public ServiceItem service(Long id) {
        return services.findById(id).orElseThrow(() -> new NotFoundException("Service not found", "SERVICE_NOT_FOUND"));
    }

    @Transactional
    public ServiceItem inactiveService(Long id) {
        ServiceItem service = service(id);
        service.status = RecordStatus.INACTIVE;
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
        if (prices.overlaps(service.id, request.effectiveFrom(), effectiveTo)) {
            throw new BusinessException("Price period overlaps existing price", "SERVICE_PRICE_OVERLAP");
        }
        ServicePrice price = new ServicePrice();
        price.serviceItem = service;
        price.unitPrice = request.unitPrice();
        price.effectiveFrom = request.effectiveFrom();
        price.effectiveTo = request.effectiveTo();
        price.notes = request.notes();
        return prices.save(price);
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
        return contracts.findByPrimaryTenantIdAndIsDeletedFalse(tenantId, pageable);
    }

    public RentalContract tenantCurrentContract(Long userId) {
        return contracts.findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalse(userId, ContractStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Current contract not found", "CONTRACT_NOT_FOUND"));
    }

    public Page<RentalContract> tenantContractHistory(Long userId, Pageable pageable) {
        return contracts.findByPrimaryTenantUserIdAndIsDeletedFalse(userId, pageable);
    }
}
