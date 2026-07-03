package com.example.rentalmanagement.notification.service;

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
public class NotificationService {
    private final NotificationRepository notifications;
    private final UserRepository users;
    private final CurrentUser currentUser;

    public NotificationService(NotificationRepository notifications, UserRepository users, CurrentUser currentUser) {
        this.notifications = notifications;
        this.users = users;
        this.currentUser = currentUser;
    }

    @Transactional
    public Notification create(User user, NotificationType type, String title, String content) {
        Notification n = new Notification();
        n.user = user;
        n.type = type;
        n.title = title;
        n.content = content;
        return notifications.save(n);
    }

    @Transactional
    public Notification createGeneral(NotificationGeneralRequest request) {
        User user = users.findById(request.userId()).orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        return create(user, NotificationType.GENERAL, request.title(), request.content());
    }

    public Page<Notification> mine(Pageable pageable) {
        return notifications.findByUserIdOrderByCreatedAtDesc(currentUser.userId(), pageable);
    }

    public long unreadCount() {
        return notifications.countByUserIdAndIsReadFalse(currentUser.userId());
    }

    @Transactional
    public Notification markRead(Long id) {
        Notification n = notifications.findByIdAndUserId(id, currentUser.userId())
                .orElseThrow(() -> new NotFoundException("Notification not found", "NOTIFICATION_NOT_FOUND"));
        n.isRead = true;
        n.readAt = LocalDateTime.now();
        return n;
    }

    @Transactional
    public void markAllRead() {
        notifications.findByUserIdAndIsReadFalse(currentUser.userId()).forEach(n -> {
            n.isRead = true;
            n.readAt = LocalDateTime.now();
        });
    }
}
