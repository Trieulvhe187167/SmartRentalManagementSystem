package com.example.rentalmanagement.contract.controller;

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
@RequestMapping("/api/v1/admin")
public class ContractController {
    private final ContractManagementService contracts;

    public ContractController(ContractManagementService contracts) {
        this.contracts = contracts;
    }

    @PostMapping("/contracts")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<RentalContract> create(@Valid @RequestBody ContractCreateRequest request) {
        return ApiResponse.success("Created", contracts.createContract(request));
    }

    @GetMapping("/contracts")
    public ApiResponse<PageResponse<RentalContract>> list(@RequestParam(required = false) ContractStatus status,
                                                   @RequestParam(required = false) Long roomId,
                                                   @RequestParam(required = false) Long tenantId,
                                                   Pageable pageable) {
        return ApiResponse.success(PageResponse.from(contracts.search(status, roomId, tenantId, pageable)));
    }

    @GetMapping("/contracts/{id}")
    public ApiResponse<RentalContract> detail(@PathVariable Long id) {
        return ApiResponse.success(contracts.contract(id));
    }

    @PutMapping("/contracts/{id}")
    public ApiResponse<RentalContract> update(@PathVariable Long id, @Valid @RequestBody ContractCreateRequest request) {
        return ApiResponse.success(contracts.updateDraftContract(id, request));
    }

    @PostMapping("/contracts/{id}/occupants")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ContractOccupant> addOccupant(@PathVariable Long id, @Valid @RequestBody ContractOccupantRequest request) {
        return ApiResponse.success("Created", contracts.addOccupant(id, request));
    }

    @GetMapping("/contracts/{id}/occupants")
    public ApiResponse<List<ContractOccupant>> occupants(@PathVariable Long id) {
        return ApiResponse.success(contracts.contractOccupantList(id));
    }

    @PostMapping("/contracts/{id}/occupants/new")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ContractOccupant> createOccupant(
            @PathVariable Long id,
            @Valid @RequestBody ContractOccupantCreateRequest request
    ) {
        return ApiResponse.success("Created", contracts.createAndAddOccupant(id, request));
    }

    @DeleteMapping("/contracts/{id}/occupants/{occupantId}")
    public ApiResponse<ContractOccupant> removeOccupant(@PathVariable Long id, @PathVariable Long occupantId) {
        return ApiResponse.success(contracts.removeOrMoveOutOccupant(id, occupantId));
    }

    @PostMapping("/contracts/{id}/services")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ContractService> addContractService(@PathVariable Long id, @Valid @RequestBody ContractServiceAssignRequest request) {
        return ApiResponse.success("Created", contracts.saveContractService(id, request));
    }

    @PutMapping("/contracts/{id}/activate")
    public ApiResponse<RentalContract> activate(@PathVariable Long id) {
        return ApiResponse.success(contracts.activate(id));
    }

    @PutMapping("/contracts/{id}/terminate")
    public ApiResponse<RentalContract> terminate(@PathVariable Long id, @RequestBody ContractTerminateRequest request) {
        return ApiResponse.success(contracts.terminate(id, request));
    }

    @PutMapping("/contracts/{id}/renew")
    public ApiResponse<RentalContract> renew(@PathVariable Long id, @Valid @RequestBody ContractRenewRequest request) {
        return ApiResponse.success(contracts.renew(id, request));
    }

    @PutMapping("/contracts/{id}/expire")
    public ApiResponse<RentalContract> expire(@PathVariable Long id) {
        return ApiResponse.success(contracts.expire(id));
    }

    @PostMapping("/services")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ServiceItem> createService(@Valid @RequestBody ServiceRequest request) {
        return ApiResponse.success("Created", contracts.saveService(request, null));
    }

    @GetMapping("/services")
    public ApiResponse<PageResponse<ServiceItem>> services(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(contracts.services(pageable)));
    }

    @GetMapping("/services/{id}")
    public ApiResponse<ServiceItem> service(@PathVariable Long id) {
        return ApiResponse.success(contracts.service(id));
    }

    @PutMapping("/services/{id}")
    public ApiResponse<ServiceItem> updateService(@PathVariable Long id, @Valid @RequestBody ServiceRequest request) {
        return ApiResponse.success(contracts.saveService(request, id));
    }

    @PutMapping("/services/{id}/inactive")
    public ApiResponse<ServiceItem> inactiveService(@PathVariable Long id) {
        return ApiResponse.success(contracts.inactiveService(id));
    }

    @PutMapping({"/services/{id}/deactivate", "/services/{id}/activate"})
    public ApiResponse<ServiceItem> setServiceActive(@PathVariable Long id, jakarta.servlet.http.HttpServletRequest request) {
        return ApiResponse.success(contracts.setServiceActive(id, request.getRequestURI().endsWith("/activate")));
    }

    @GetMapping("/services/{serviceId}/prices")
    public ApiResponse<PageResponse<ServicePrice>> servicePrices(@PathVariable Long serviceId, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(contracts.servicePrices(serviceId, pageable)));
    }

    @PostMapping("/services/{serviceId}/prices")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ServicePrice> addServicePrice(@PathVariable Long serviceId, @Valid @RequestBody ServicePriceRequest request) {
        return ApiResponse.success("Created", contracts.addPrice(new ServicePriceRequest(serviceId, request.unitPrice(), request.effectiveFrom(), request.effectiveTo(), request.notes())));
    }

    @PostMapping("/service-prices")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ServicePrice> addPrice(@Valid @RequestBody ServicePriceRequest request) {
        return ApiResponse.success("Created", contracts.addPrice(request));
    }

    @PutMapping("/service-prices/{id}")
    public ApiResponse<ServicePrice> updatePrice(@PathVariable Long id, @Valid @RequestBody ServicePriceRequest request) {
        return ApiResponse.success(contracts.updatePrice(id, request));
    }

    @PostMapping("/contract-services")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ContractService> contractService(@Valid @RequestBody ContractServiceRequest request) {
        return ApiResponse.success("Created", contracts.saveContractService(request));
    }

    @GetMapping("/contracts/{id}/services")
    public ApiResponse<PageResponse<ContractService>> contractServices(@PathVariable Long id, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(contracts.contractServices(id, pageable)));
    }

    @PutMapping("/contract-services/{id}/inactive")
    public ApiResponse<ContractService> inactiveContractService(@PathVariable Long id) {
        return ApiResponse.success(contracts.inactiveContractService(id));
    }
}
