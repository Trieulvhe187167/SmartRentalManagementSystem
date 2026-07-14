package com.example.rentalmanagement.building.service;

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

@Service
public class PropertyService {
    private final BuildingRepository buildings;
    private final FloorRepository floors;
    private final RoomRepository rooms;
    private final UserRepository users;
    private final TenantProfileRepository tenants;
    private final OccupantRepository occupants;
    private final RentalContractRepository contracts;
    private final InvoiceRepository invoices;

    public PropertyService(BuildingRepository buildings, FloorRepository floors, RoomRepository rooms, UserRepository users, TenantProfileRepository tenants, OccupantRepository occupants, RentalContractRepository contracts, InvoiceRepository invoices) {
        this.buildings = buildings;
        this.floors = floors;
        this.rooms = rooms;
        this.users = users;
        this.tenants = tenants;
        this.occupants = occupants;
        this.contracts = contracts;
        this.invoices = invoices;
    }

    @Transactional
    public Building saveBuilding(BuildingRequest request, Long id) {
        Building b = id == null ? new Building() : buildings.findById(id).orElseThrow(() -> new NotFoundException("Building not found", "BUILDING_NOT_FOUND"));
        if (id == null && buildings.existsByCode(request.code())) {
            throw new BusinessException("Building code already exists", "BUILDING_CODE_EXISTS");
        }
        b.code = request.code();
        b.name = request.name();
        b.address = request.address();
        return buildings.save(b);
    }

    public Page<Building> buildings(Pageable pageable) {
        return buildings.findAll(pageable);
    }

    public Building building(Long id) {
        return buildings.findById(id).orElseThrow(() -> new NotFoundException("Building not found", "BUILDING_NOT_FOUND"));
    }

    @Transactional
    public Building inactiveBuilding(Long id) {
        Building building = building(id);
        building.status = RecordStatus.INACTIVE;
        return building;
    }

    @Transactional
    public Floor saveFloor(FloorRequest request, Long id) {
        Floor f = id == null ? new Floor() : floors.findById(id).orElseThrow(() -> new NotFoundException("Floor not found", "FLOOR_NOT_FOUND"));
        if (id == null && floors.existsByBuildingIdAndFloorNumber(request.buildingId(), request.floorNumber())) {
            throw new BusinessException("Floor number already exists in building", "FLOOR_EXISTS");
        }
        f.building = building(request.buildingId());
        f.floorNumber = request.floorNumber();
        f.name = request.name();
        return floors.save(f);
    }

    public Page<Floor> floors(Long buildingId, Pageable pageable) {
        return buildingId == null ? floors.findAll(pageable) : floors.findByBuildingId(buildingId, pageable);
    }

    public Floor floor(Long id) {
        return floors.findById(id).orElseThrow(() -> new NotFoundException("Floor not found", "FLOOR_NOT_FOUND"));
    }

    @Transactional
    public Floor inactiveFloor(Long id) {
        Floor floor = floor(id);
        floor.status = RecordStatus.INACTIVE;
        return floor;
    }

    @Transactional
    public Room saveRoom(RoomRequest request, Long id) {
        Room room = id == null ? new Room() : rooms.findById(id).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
        if (id == null && rooms.existsByBuildingIdAndRoomNumber(request.buildingId(), request.roomNumber())) {
            throw new BusinessException("Room number already exists in building", "ROOM_EXISTS");
        }
        Building building = building(request.buildingId());
        Floor floor = floors.findById(request.floorId()).orElseThrow(() -> new NotFoundException("Floor not found", "FLOOR_NOT_FOUND"));
        if (!floor.building.id.equals(building.id)) {
            throw new BusinessException("Floor does not belong to building", "FLOOR_BUILDING_MISMATCH");
        }
        room.building = building;
        room.floor = floor;
        room.roomNumber = request.roomNumber();
        room.areaM2 = request.areaM2();
        room.defaultRent = request.defaultRent();
        room.defaultDeposit = request.defaultDeposit();
        room.maxOccupants = request.maxOccupants();
        room.description = request.description();
        if (id == null) {
            room.status = RoomStatus.AVAILABLE;
        }
        return rooms.save(room);
    }

    public Page<Room> rooms(RoomStatus status, Long buildingId, Long floorId, String keyword, Pageable pageable) {
        return rooms.search(status, buildingId, floorId, keyword, pageable);
    }

    public Room room(Long id) {
        return rooms.findById(id).orElseThrow(() -> new NotFoundException("Room not found", "ROOM_NOT_FOUND"));
    }

    public RentalContract currentRoomTenant(Long roomId) {
        return contracts.findFirstByRoomIdAndStatusAndIsDeletedFalse(roomId, ContractStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Current tenant not found", "CURRENT_TENANT_NOT_FOUND"));
    }

    @Transactional
    public Room updateRoomStatus(Long id, RoomStatusRequest request) {
        Room room = room(id);
        room.status = request.status();
        return room;
    }

    @Transactional
    public Room updateRoomStatus(Long id, RoomStatus status) {
        Room room = room(id);
        room.status = status;
        return room;
    }

    @Transactional
    public TenantProfile saveTenant(TenantProfileRequest request, Long id) {
        TenantProfile t = id == null ? new TenantProfile() : tenants.findById(id).orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND"));
        User user = users.findById(request.userId()).orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        if (!"TENANT".equals(user.roleName())) {
            throw new BusinessException("User must have TENANT role", "USER_NOT_TENANT");
        }
        tenants.findByIdentityNumber(request.identityNumber())
                .filter(existing -> id == null || !existing.id.equals(id))
                .ifPresent(existing -> {
                    throw new BusinessException("Identity number already exists", "TENANT_IDENTITY_EXISTS");
                });
        if (request.phone() != null && !request.phone().isBlank()) {
            users.findByPhone(request.phone())
                    .filter(existing -> !existing.id.equals(user.id))
                    .ifPresent(existing -> {
                        throw new BusinessException("Phone already exists", "USER_PHONE_EXISTS");
                    });
        }
        if (request.email() != null && !request.email().isBlank()) {
            users.findByEmail(request.email())
                    .filter(existing -> !existing.id.equals(user.id))
                    .ifPresent(existing -> {
                        throw new BusinessException("Email already exists", "USER_EMAIL_EXISTS");
                    });
        }
        t.user = user;
        t.fullName = request.fullName();
        t.dateOfBirth = request.dateOfBirth();
        t.identityType = request.identityType();
        t.identityNumber = request.identityNumber();
        t.identityIssuedDate = request.identityIssuedDate();
        t.identityIssuedPlace = request.identityIssuedPlace();
        t.user.phone = request.phone();
        t.user.email = request.email();
        t.permanentAddress = request.permanentAddress();
        t.emergencyContactName = request.emergencyContactName();
        t.emergencyContactPhone = request.emergencyContactPhone();
        return tenants.save(t);
    }

    public Page<TenantProfile> tenants(String keyword, boolean includeArchived, Pageable pageable) {
        return tenants.search(keyword, includeArchived, pageable).map(this::withCurrentRoom);
    }

    public TenantProfile tenant(Long id) {
        return withCurrentRoom(tenants.findById(id).orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND")));
    }

    public TenantProfile tenantProfileForUser(Long userId) {
        return withCurrentRoom(tenants.findByUserId(userId).orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND")));
    }

    @Transactional
    public TenantProfile archiveTenant(Long id) {
        TenantProfile tenant = tenant(id);
        tenant.status = RecordStatus.INACTIVE;
        tenant.user.status = UserStatus.INACTIVE;
        return tenant;
    }

    @Transactional
    public TenantProfile restoreTenant(Long id) {
        TenantProfile tenant = tenant(id);
        tenant.status = RecordStatus.ACTIVE;
        tenant.user.status = UserStatus.ACTIVE;
        tenant.user.isDeleted = false;
        tenant.user.deletedAt = null;
        return tenant;
    }

    @Transactional
    public void deleteTenant(Long id) {
        TenantProfile tenant = tenant(id);
        if (contracts.existsByPrimaryTenantIdAndIsDeletedFalse(id) || invoices.existsByTenantProfileIdAndIsDeletedFalse(id)) {
            throw new BusinessException(
                    "Cannot delete tenant with contracts or invoices. Archive the tenant instead.",
                    "TENANT_HAS_HISTORY",
                    HttpStatus.BAD_REQUEST
            );
        }
        User user = tenant.user;
        tenants.delete(tenant);
        if (user != null) {
            user.status = UserStatus.INACTIVE;
            user.isDeleted = true;
            user.deletedAt = LocalDateTime.now();
            user.phone = null;
            user.email = null;
            user.username = deletedUsername(user);
        }
    }

    private String deletedUsername(User user) {
        String base = user.username == null ? "user" : user.username;
        String prefix = "deleted_" + user.id + "_";
        int maxBaseLength = Math.max(0, 100 - prefix.length());
        if (base.length() > maxBaseLength) {
            base = base.substring(0, maxBaseLength);
        }
        return prefix + base;
    }

    private TenantProfile withCurrentRoom(TenantProfile tenant) {
        contracts.findFirstByPrimaryTenantIdAndStatusAndIsDeletedFalse(tenant.id, ContractStatus.ACTIVE)
                .map(contract -> contract.room)
                .map(room -> room.roomNumber)
                .ifPresent(roomNumber -> tenant.currentRoom = roomNumber);
        return tenant;
    }

    @Transactional
    public Occupant saveOccupant(OccupantRequest request, Long id) {
        Occupant o = id == null ? new Occupant() : occupants.findById(id).orElseThrow(() -> new NotFoundException("Occupant not found", "OCCUPANT_NOT_FOUND"));
        o.fullName = request.fullName();
        o.dateOfBirth = request.dateOfBirth();
        o.identityType = request.identityType();
        o.identityNumber = request.identityNumber();
        o.phone = request.phone();
        o.permanentAddress = request.permanentAddress();
        return occupants.save(o);
    }

    public Page<Occupant> occupants(Long tenantProfileId, Pageable pageable) {
        return occupants.findAll(pageable);
    }

    public Occupant occupant(Long id) {
        return occupants.findById(id).orElseThrow(() -> new NotFoundException("Occupant not found", "OCCUPANT_NOT_FOUND"));
    }
}
