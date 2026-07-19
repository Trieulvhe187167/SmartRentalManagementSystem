package com.example.rentalmanagement.contract.service;

import com.example.rentalmanagement.common.enums.ContractStatus;
import com.example.rentalmanagement.common.enums.RoomStatus;
import com.example.rentalmanagement.common.exception.BusinessException;
import com.example.rentalmanagement.contract.RentalContract;
import com.example.rentalmanagement.contract.dto.ContractCreateRequest;
import com.example.rentalmanagement.contract.dto.ContractRejectionRequest;
import com.example.rentalmanagement.contract.repository.ContractOccupantRepository;
import com.example.rentalmanagement.contract.repository.ContractServiceRepository;
import com.example.rentalmanagement.contract.repository.RentalContractRepository;
import com.example.rentalmanagement.room.Room;
import com.example.rentalmanagement.room.repository.RoomRepository;
import com.example.rentalmanagement.serviceitem.repository.ServiceItemRepository;
import com.example.rentalmanagement.serviceitem.repository.ServicePriceRepository;
import com.example.rentalmanagement.tenant.TenantProfile;
import com.example.rentalmanagement.tenant.repository.OccupantRepository;
import com.example.rentalmanagement.tenant.repository.TenantProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContractTenantConfirmationTest {
    @Mock RentalContractRepository contracts;
    @Mock RoomRepository rooms;
    @Mock TenantProfileRepository tenants;
    @Mock OccupantRepository occupants;
    @Mock ContractOccupantRepository contractOccupants;
    @Mock ServiceItemRepository services;
    @Mock ServicePriceRepository prices;
    @Mock ContractServiceRepository contractServices;

    private ContractManagementService service;

    @BeforeEach
    void setUp() {
        service = new ContractManagementService(
                contracts,
                rooms,
                tenants,
                occupants,
                contractOccupants,
                services,
                prices,
                contractServices
        );
    }

    @Test
    void tenantCanConfirmOwnPendingContract() {
        RentalContract contract = pendingContract();
        when(contracts.findByIdAndPrimaryTenantUserIdAndIsDeletedFalse(11L, 7L))
                .thenReturn(Optional.of(contract));
        when(contracts.existsByRoomIdAndStatusAndIsDeletedFalse(3L, ContractStatus.ACTIVE))
                .thenReturn(false);

        RentalContract result = service.confirmByTenant(7L, 11L);

        assertEquals(ContractStatus.ACTIVE, result.status);
        assertEquals(RoomStatus.OCCUPIED, result.room.status);
        assertNotNull(result.tenantConfirmedAt);
        assertNotNull(result.activatedAt);
    }

    @Test
    void adminCannotCreateContractForTenantWithActiveContract() {
        Room room = new Room();
        room.id = 9L;
        room.status = RoomStatus.AVAILABLE;
        TenantProfile tenant = new TenantProfile();
        tenant.id = 5L;
        ContractCreateRequest request = new ContractCreateRequest(
                "HD-2026-099",
                room.id,
                tenant.id,
                LocalDate.of(2026, 8, 1),
                LocalDate.of(2027, 7, 31),
                new BigDecimal("3000000"),
                new BigDecimal("3000000"),
                5,
                null
        );
        when(rooms.findById(room.id)).thenReturn(Optional.of(room));
        when(tenants.findById(tenant.id)).thenReturn(Optional.of(tenant));
        when(contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalse(tenant.id, ContractStatus.ACTIVE))
                .thenReturn(true);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.createContract(request)
        );

        assertEquals("TENANT_ACTIVE_CONTRACT_EXISTS", exception.errorCode);
    }

    @Test
    void tenantCanRejectOwnPendingContractWithReason() {
        RentalContract contract = pendingContract();
        when(contracts.findByIdAndPrimaryTenantUserIdAndIsDeletedFalse(11L, 7L))
                .thenReturn(Optional.of(contract));

        RentalContract result = service.rejectByTenant(
                7L,
                11L,
                new ContractRejectionRequest("  Thong tin tien coc chua dung  ")
        );

        assertEquals(ContractStatus.REJECTED, result.status);
        assertEquals("Thong tin tien coc chua dung", result.tenantRejectionReason);
        assertNotNull(result.tenantRejectedAt);
        assertEquals(RoomStatus.AVAILABLE, result.room.status);
    }

    @Test
    void tenantCannotConfirmContractThatIsAlreadyActive() {
        RentalContract contract = pendingContract();
        contract.status = ContractStatus.ACTIVE;
        when(contracts.findByIdAndPrimaryTenantUserIdAndIsDeletedFalse(11L, 7L))
                .thenReturn(Optional.of(contract));

        assertThrows(BusinessException.class, () -> service.confirmByTenant(7L, 11L));
    }

    @Test
    void tenantCannotConfirmASecondActiveContract() {
        RentalContract contract = pendingContract();
        when(contracts.findByIdAndPrimaryTenantUserIdAndIsDeletedFalse(11L, 7L))
                .thenReturn(Optional.of(contract));
        when(contracts.existsByPrimaryTenantIdAndStatusAndIsDeletedFalse(5L, ContractStatus.ACTIVE))
                .thenReturn(true);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.confirmByTenant(7L, 11L)
        );

        assertEquals("TENANT_ACTIVE_CONTRACT_EXISTS", exception.errorCode);
        assertEquals(ContractStatus.PENDING_CONFIRMATION, contract.status);
        assertEquals(RoomStatus.AVAILABLE, contract.room.status);
    }

    @Test
    void adminCannotBypassTenantConfirmation() {
        RentalContract contract = pendingContract();
        when(contracts.findById(11L)).thenReturn(Optional.of(contract));

        assertThrows(BusinessException.class, () -> service.activate(11L));
        assertEquals(ContractStatus.PENDING_CONFIRMATION, contract.status);
    }

    private RentalContract pendingContract() {
        Room room = new Room();
        room.id = 3L;
        room.status = RoomStatus.AVAILABLE;

        TenantProfile tenant = new TenantProfile();
        tenant.id = 5L;

        RentalContract contract = new RentalContract();
        contract.id = 11L;
        contract.room = room;
        contract.primaryTenant = tenant;
        contract.status = ContractStatus.PENDING_CONFIRMATION;
        return contract;
    }
}
