package com.example.rentalmanagement.building.controller;

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
public class PropertyController {
    private final PropertyService property;
    private final ContractManagementService contracts;

    public PropertyController(PropertyService property, ContractManagementService contracts) {
        this.property = property;
        this.contracts = contracts;
    }

    @PostMapping("/buildings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Building> createBuilding(@Valid @RequestBody BuildingRequest request) {
        return ApiResponse.success("Created", property.saveBuilding(request, null));
    }

    @GetMapping("/buildings")
    public ApiResponse<PageResponse<Building>> buildings(Pageable pageable) {
        return ApiResponse.success(PageResponse.from(property.buildings(pageable)));
    }

    @GetMapping("/buildings/{id}")
    public ApiResponse<Building> building(@PathVariable Long id) {
        return ApiResponse.success(property.building(id));
    }

    @PutMapping("/buildings/{id}")
    public ApiResponse<Building> updateBuilding(@PathVariable Long id, @Valid @RequestBody BuildingRequest request) {
        return ApiResponse.success(property.saveBuilding(request, id));
    }

    @PutMapping("/buildings/{id}/inactive")
    public ApiResponse<Building> inactiveBuilding(@PathVariable Long id) {
        return ApiResponse.success(property.inactiveBuilding(id));
    }

    @PostMapping("/floors")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Floor> createFloor(@Valid @RequestBody FloorRequest request) {
        return ApiResponse.success("Created", property.saveFloor(request, null));
    }

    @GetMapping("/floors")
    public ApiResponse<PageResponse<Floor>> floors(@RequestParam(required = false) Long buildingId, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(property.floors(buildingId, pageable)));
    }

    @GetMapping("/buildings/{buildingId}/floors")
    public ApiResponse<PageResponse<Floor>> floorsByBuilding(@PathVariable Long buildingId, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(property.floors(buildingId, pageable)));
    }

    @GetMapping("/floors/{id}")
    public ApiResponse<Floor> floor(@PathVariable Long id) {
        return ApiResponse.success(property.floor(id));
    }

    @PutMapping("/floors/{id}")
    public ApiResponse<Floor> updateFloor(@PathVariable Long id, @Valid @RequestBody FloorRequest request) {
        return ApiResponse.success(property.saveFloor(request, id));
    }

    @PutMapping("/floors/{id}/inactive")
    public ApiResponse<Floor> inactiveFloor(@PathVariable Long id) {
        return ApiResponse.success(property.inactiveFloor(id));
    }

    @PostMapping("/rooms")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Room> createRoom(@Valid @RequestBody RoomRequest request) {
        return ApiResponse.success("Created", property.saveRoom(request, null));
    }

    @GetMapping("/rooms")
    public ApiResponse<PageResponse<Room>> rooms(@RequestParam(required = false) RoomStatus status,
                                          @RequestParam(required = false) Long buildingId,
                                          @RequestParam(required = false) Long floorId,
                                          @RequestParam(required = false) String keyword,
                                          Pageable pageable) {
        return ApiResponse.success(PageResponse.from(property.rooms(status, buildingId, floorId, keyword, pageable)));
    }

    @GetMapping("/rooms/{id}")
    public ApiResponse<Room> room(@PathVariable Long id) {
        return ApiResponse.success(property.room(id));
    }

    @GetMapping("/rooms/{id}/current-tenant")
    public ApiResponse<RentalContract> roomCurrentTenant(@PathVariable Long id) {
        return ApiResponse.success(property.currentRoomTenant(id));
    }

    @PutMapping("/rooms/{id}")
    public ApiResponse<Room> updateRoom(@PathVariable Long id, @Valid @RequestBody RoomRequest request) {
        return ApiResponse.success(property.saveRoom(request, id));
    }

    @PutMapping("/rooms/{id}/status")
    public ApiResponse<Room> roomStatus(@PathVariable Long id, @Valid @RequestBody RoomStatusRequest request) {
        return ApiResponse.success(property.updateRoomStatus(id, request));
    }

    @PutMapping("/rooms/{id}/maintenance")
    public ApiResponse<Room> roomMaintenance(@PathVariable Long id) {
        return ApiResponse.success(property.updateRoomStatus(id, RoomStatus.MAINTENANCE));
    }

    @PutMapping({"/rooms/{id}/inactive", "/rooms/{id}/deactivate"})
    public ApiResponse<Room> roomInactive(@PathVariable Long id) {
        return ApiResponse.success(property.updateRoomStatus(id, RoomStatus.INACTIVE));
    }

    @PutMapping({"/rooms/{id}/available", "/rooms/{id}/activate"})
    public ApiResponse<Room> roomAvailable(@PathVariable Long id) {
        return ApiResponse.success(property.updateRoomStatus(id, RoomStatus.AVAILABLE));
    }

    @PostMapping("/tenants")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TenantProfile> createTenant(@Valid @RequestBody TenantProfileRequest request) {
        return ApiResponse.success("Created", property.saveTenant(request, null));
    }

    @GetMapping("/tenants")
    public ApiResponse<PageResponse<TenantProfile>> tenants(@RequestParam(required = false) String keyword, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(property.tenants(keyword, pageable)));
    }

    @GetMapping("/tenants/{id}")
    public ApiResponse<TenantProfile> tenant(@PathVariable Long id) {
        return ApiResponse.success(property.tenant(id));
    }

    @PutMapping("/tenants/{id}")
    public ApiResponse<TenantProfile> updateTenant(@PathVariable Long id, @Valid @RequestBody TenantProfileRequest request) {
        return ApiResponse.success(property.saveTenant(request, id));
    }

    @GetMapping("/tenants/{id}/contracts")
    public ApiResponse<PageResponse<RentalContract>> tenantContracts(@PathVariable Long id, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(contracts.tenantContracts(id, pageable)));
    }

    @PostMapping("/occupants")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Occupant> createOccupant(@Valid @RequestBody OccupantRequest request) {
        return ApiResponse.success("Created", property.saveOccupant(request, null));
    }

    @GetMapping("/occupants")
    public ApiResponse<PageResponse<Occupant>> occupants(@RequestParam(required = false) Long tenantProfileId, Pageable pageable) {
        return ApiResponse.success(PageResponse.from(property.occupants(tenantProfileId, pageable)));
    }

    @GetMapping("/occupants/{id}")
    public ApiResponse<Occupant> occupant(@PathVariable Long id) {
        return ApiResponse.success(property.occupant(id));
    }

    @PutMapping("/occupants/{id}")
    public ApiResponse<Occupant> updateOccupant(@PathVariable Long id, @Valid @RequestBody OccupantRequest request) {
        return ApiResponse.success(property.saveOccupant(request, id));
    }

    @PutMapping("/contracts/{contractId}/occupants/{occupantId}/move-out")
    public ApiResponse<ContractOccupant> moveOutOccupant(@PathVariable Long contractId, @PathVariable Long occupantId) {
        return ApiResponse.success(contracts.moveOutOccupant(contractId, occupantId));
    }
}
