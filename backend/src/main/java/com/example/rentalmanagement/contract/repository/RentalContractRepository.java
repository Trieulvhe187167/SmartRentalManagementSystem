package com.example.rentalmanagement.contract.repository;

import java.nio.charset.*;
import com.example.rentalmanagement.common.scheduling.*;

import java.math.*;
import java.time.*;
import java.util.*;
import java.io.*;
import javax.crypto.*;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

public interface RentalContractRepository extends JpaRepository<RentalContract, Long> {
    public boolean existsByContractCode(String contractCode);
    public boolean existsByRoomIdAndStatusAndIsDeletedFalse(Long roomId, ContractStatus status);
    public Optional<RentalContract> findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalse(Long userId, ContractStatus status);
    public Optional<RentalContract> findFirstByPrimaryTenantUserIdAndStatusAndIsDeletedFalseOrderByCreatedAtDesc(Long userId, ContractStatus status);
    public Optional<RentalContract> findByIdAndPrimaryTenantUserIdAndIsDeletedFalse(Long id, Long userId);
    public Optional<RentalContract> findFirstByPrimaryTenantIdAndStatusAndIsDeletedFalse(Long tenantId, ContractStatus status);
    public Optional<RentalContract> findFirstByRoomIdAndStatusAndIsDeletedFalse(Long roomId, ContractStatus status);
    public Page<RentalContract> findByPrimaryTenantUserIdAndIsDeletedFalse(Long userId, Pageable pageable);
    public Page<RentalContract> findByPrimaryTenantIdAndIsDeletedFalse(Long tenantId, Pageable pageable);
    public boolean existsByPrimaryTenantIdAndIsDeletedFalse(Long tenantId);
    public boolean existsByPrimaryTenantIdAndStatusAndIsDeletedFalse(Long tenantId, ContractStatus status);
    public boolean existsByPrimaryTenantIdAndStatusAndIsDeletedFalseAndIdNot(Long tenantId, ContractStatus status, Long id);

    @Query("""
            select c from RentalContract c
            where c.isDeleted = false
              and (:status is null or c.status = :status)
              and (:roomId is null or c.room.id = :roomId)
              and (:tenantId is null or c.primaryTenant.id = :tenantId)
            """)
    public Page<RentalContract> search(@Param("status") ContractStatus status, @Param("roomId") Long roomId, @Param("tenantId") Long tenantId, Pageable pageable);

    public List<RentalContract> findByStatusAndIsDeletedFalse(ContractStatus status);
    public List<RentalContract> findByStatusAndEndDateBetweenAndIsDeletedFalse(ContractStatus status, LocalDate from, LocalDate to);
}
