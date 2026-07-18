package com.example.rentalmanagement.contract.service;

import com.example.rentalmanagement.common.enums.RecordStatus;
import com.example.rentalmanagement.common.enums.ServiceChargeType;
import com.example.rentalmanagement.contract.repository.ContractOccupantRepository;
import com.example.rentalmanagement.contract.repository.ContractServiceRepository;
import com.example.rentalmanagement.contract.repository.RentalContractRepository;
import com.example.rentalmanagement.room.repository.RoomRepository;
import com.example.rentalmanagement.serviceitem.ServiceItem;
import com.example.rentalmanagement.serviceitem.ServicePrice;
import com.example.rentalmanagement.serviceitem.dto.ServicePriceRequest;
import com.example.rentalmanagement.serviceitem.dto.ServiceRequest;
import com.example.rentalmanagement.serviceitem.repository.ServiceItemRepository;
import com.example.rentalmanagement.serviceitem.repository.ServicePriceRepository;
import com.example.rentalmanagement.tenant.repository.TenantProfileRepository;
import com.example.rentalmanagement.tenant.repository.OccupantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContractManagementServiceServicesTest {
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
    void createsAnotherServiceOfTheSameTypeWithAUniqueCode() {
        when(services.existsByCode("ELECTRICITY")).thenReturn(true);
        when(services.existsByCode("ELECTRICITY_DIEN_HANH_LANG")).thenReturn(false);
        when(services.save(any(ServiceItem.class))).thenAnswer(invocation -> {
            ServiceItem item = invocation.getArgument(0);
            item.id = 10L;
            return item;
        });
        when(prices.findEffective(10L, LocalDate.now())).thenReturn(List.of());

        ServiceItem result = service.saveService(
                new ServiceRequest(
                        "ELECTRICITY",
                        "Điện hành lang",
                        "kWh",
                        ServiceChargeType.METERED,
                        null,
                        true
                ),
                null
        );

        assertEquals("ELECTRICITY_DIEN_HANH_LANG", result.code);
        assertEquals("ELECTRICITY", result.getType());
        assertEquals(RecordStatus.ACTIVE, result.status);
    }

    @Test
    void createsServiceAndInitialPriceTogether() {
        LocalDate effectiveFrom = LocalDate.of(2026, 7, 19);
        when(services.existsByCode("CLEANING")).thenReturn(false);
        when(services.save(any(ServiceItem.class))).thenAnswer(invocation -> {
            ServiceItem item = invocation.getArgument(0);
            item.id = 11L;
            return item;
        });
        when(services.findById(11L)).thenAnswer(invocation -> {
            ServiceItem item = new ServiceItem();
            item.id = 11L;
            return Optional.of(item);
        });
        when(prices.findEffective(11L, effectiveFrom)).thenReturn(List.of());
        when(prices.findEffective(11L, LocalDate.now())).thenReturn(List.of());
        when(prices.saveAndFlush(any(ServicePrice.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.saveService(
                new ServiceRequest(
                        "CLEANING",
                        "Rác",
                        "tháng",
                        ServiceChargeType.FIXED_PER_ROOM,
                        null,
                        true,
                        new BigDecimal("30000"),
                        effectiveFrom
                ),
                null
        );

        verify(prices).saveAndFlush(org.mockito.ArgumentMatchers.argThat(price ->
                price.serviceItem.id == 11L
                        && price.unitPrice.compareTo(new BigDecimal("30000")) == 0
                        && effectiveFrom.equals(price.effectiveFrom)
        ));
    }

    @Test
    void addingPriceClosesThePreviousEffectivePrice() {
        ServiceItem item = new ServiceItem();
        item.id = 1L;
        ServicePrice previous = new ServicePrice();
        previous.serviceItem = item;
        previous.effectiveFrom = LocalDate.of(2026, 1, 1);

        LocalDate effectiveFrom = LocalDate.of(2026, 7, 19);
        when(services.findById(1L)).thenReturn(Optional.of(item));
        when(prices.findEffective(1L, effectiveFrom)).thenReturn(List.of(previous));
        when(prices.saveAndFlush(any(ServicePrice.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ServicePrice result = service.addPrice(
                new ServicePriceRequest(1L, new BigDecimal("3800"), effectiveFrom, null, "Điều chỉnh giá")
        );

        assertEquals(LocalDate.of(2026, 7, 18), previous.effectiveTo);
        assertEquals(new BigDecimal("3800"), result.unitPrice);
        assertEquals(effectiveFrom, result.effectiveFrom);
        verify(prices).flush();
    }

    @Test
    void addingPriceOnTheSameDateUpdatesTheExistingRecord() {
        ServiceItem item = new ServiceItem();
        item.id = 4L;
        ServicePrice existing = new ServicePrice();
        existing.id = 20L;
        existing.serviceItem = item;
        existing.unitPrice = new BigDecimal("50000");
        existing.effectiveFrom = LocalDate.of(2026, 7, 19);

        LocalDate effectiveFrom = LocalDate.of(2026, 7, 19);
        when(services.findById(4L)).thenReturn(Optional.of(item));
        when(prices.findEffective(4L, effectiveFrom)).thenReturn(List.of(existing));
        when(prices.saveAndFlush(existing)).thenReturn(existing);

        ServicePrice result = service.addPrice(
                new ServicePriceRequest(4L, new BigDecimal("30000"), effectiveFrom, null, "Điều chỉnh trong ngày")
        );

        assertEquals(20L, result.id);
        assertEquals(new BigDecimal("30000"), result.unitPrice);
        verify(prices, never()).flush();
    }
}
