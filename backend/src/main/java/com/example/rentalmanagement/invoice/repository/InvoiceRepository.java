package com.example.rentalmanagement.invoice.repository;

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
import com.example.rentalmanagement.contract.repository.*;
import com.example.rentalmanagement.contract.service.*;
import com.example.rentalmanagement.dashboard.dto.*;
import com.example.rentalmanagement.dashboard.service.*;
import com.example.rentalmanagement.invoice.*;
import com.example.rentalmanagement.invoice.dto.*;
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

public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
    public boolean existsByContractIdAndBillingMonthAndBillingYearAndStatusNotAndIsDeletedFalse(Long contractId, Integer month, Integer year, InvoiceStatus status);
    public Page<Invoice> findByTenantProfileUserIdAndIsDeletedFalse(Long userId, Pageable pageable);
    public Page<Invoice> findByTenantProfileUserIdAndStatusInAndIsDeletedFalse(Long userId, Collection<InvoiceStatus> statuses, Pageable pageable);
    public Optional<Invoice> findByIdAndTenantProfileUserIdAndIsDeletedFalse(Long id, Long userId);
    public List<Invoice> findByStatusInAndDueDateBeforeAndIsDeletedFalse(Collection<InvoiceStatus> statuses, LocalDate date);
    public List<Invoice> findByStatusAndDueDateBetweenAndIsDeletedFalse(InvoiceStatus status, LocalDate from, LocalDate to);

    @Query("""
            select i from Invoice i
            where i.isDeleted = false
              and (:status is null or i.status = :status)
              and (:billingMonth is null or i.billingMonth = :billingMonth)
              and (:billingYear is null or i.billingYear = :billingYear)
            """)
    public Page<Invoice> search(@Param("status") InvoiceStatus status,
                                @Param("billingMonth") Integer billingMonth,
                                @Param("billingYear") Integer billingYear,
                                Pageable pageable);

    @Query("""
            select i from Invoice i
            where i.isDeleted = false
              and i.status in :statuses
            order by i.dueDate asc
            """)
    public Page<Invoice> debts(@Param("statuses") Collection<InvoiceStatus> statuses, Pageable pageable);
}
