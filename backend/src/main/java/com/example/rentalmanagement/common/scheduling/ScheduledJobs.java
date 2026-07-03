package com.example.rentalmanagement.common.scheduling;

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
public class ScheduledJobs {
    private final BillingService billing;
    private final RentalContractRepository contracts;
    private final InvoiceRepository invoices;
    private final NotificationService notifications;

    public ScheduledJobs(BillingService billing, RentalContractRepository contracts, InvoiceRepository invoices, NotificationService notifications) {
        this.billing = billing;
        this.contracts = contracts;
        this.invoices = invoices;
        this.notifications = notifications;
    }

    @Scheduled(cron = "0 0 1 * * *")
    @Transactional
    public void dailyJobs() {
        billing.markOverdueInvoices();
        LocalDate now = LocalDate.now();
        invoices.findByStatusAndDueDateBetweenAndIsDeletedFalse(InvoiceStatus.ISSUED, now.plusDays(1), now.plusDays(3))
                .forEach(i -> notifications.create(i.contract.primaryTenant.user, NotificationType.INVOICE_DUE_SOON, "Invoice due soon", "Invoice " + i.invoiceNumber + " is due soon."));
        contracts.findByStatusAndEndDateBetweenAndIsDeletedFalse(ContractStatus.ACTIVE, now.plusDays(7), now.plusDays(30))
                .forEach(c -> notifications.create(c.primaryTenant.user, NotificationType.CONTRACT_EXPIRING, "Contract expiring", "Contract " + c.contractCode + " is close to expiration."));
    }

    public static LocalDate dueDate(int year, int month, int day) {
        YearMonth ym = YearMonth.of(year, month);
        return LocalDate.of(year, month, Math.min(day, ym.lengthOfMonth()));
    }
}
