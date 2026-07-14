package com.example.rentalmanagement.auth.service;

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
public class AuthService {
    private static final java.time.Duration PASSWORD_RESET_TTL = java.time.Duration.ofMinutes(15);

    private final UserRepository users;
    private final RoleRepository roles;
    private final TenantProfileRepository tenantProfiles;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokens;
    private final CurrentUser currentUser;
    private final java.security.SecureRandom secureRandom = new java.security.SecureRandom();
    private final java.util.concurrent.ConcurrentMap<String, PasswordResetToken> passwordResetTokens = new java.util.concurrent.ConcurrentHashMap<>();

    public AuthService(UserRepository users, RoleRepository roles, TenantProfileRepository tenantProfiles, PasswordEncoder passwordEncoder, JwtTokenProvider tokens, CurrentUser currentUser) {
        this.users = users;
        this.roles = roles;
        this.tenantProfiles = tenantProfiles;
        this.passwordEncoder = passwordEncoder;
        this.tokens = tokens;
        this.currentUser = currentUser;
    }

    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = users.findByUsername(request.username())
                .orElseThrow(() -> new UnauthorizedException("Username or password is incorrect", "AUTH_INVALID_CREDENTIALS"));
        if (user.status == UserStatus.LOCKED) {
            throw new UnauthorizedException("Account is locked", "AUTH_ACCOUNT_LOCKED");
        }
        if (user.status == UserStatus.INACTIVE) {
            throw new UnauthorizedException("Account is inactive", "AUTH_ACCOUNT_INACTIVE");
        }
        if (!passwordEncoder.matches(request.password(), user.passwordHash)) {
            throw new UnauthorizedException("Username or password is incorrect", "AUTH_INVALID_CREDENTIALS");
        }
        user.lastLoginAt = LocalDateTime.now();
        return new LoginResponse(tokens.generate(user), "Bearer", tokens.expiresInSeconds(), user.id, user.username, user.roleName(), user.mustChangePassword);
    }

    public UserResponse me() {
        User user = currentUser.requireUser();
        TenantProfile profile = tenantProfiles.findByUserId(user.id).orElse(null);
        return UserResponse.from(user, profile);
    }

    public ForgotPasswordResponse forgotPassword(ForgotPasswordRequest request) {
        cleanupExpiredPasswordResetTokens();
        Optional<User> found = findUserForPasswordReset(request.usernameOrEmail());
        if (found.isEmpty()) {
            return new ForgotPasswordResponse(null, null);
        }
        User user = found.get();
        if (user.status != UserStatus.ACTIVE) {
            return new ForgotPasswordResponse(null, null);
        }
        String token = generatePasswordResetToken();
        LocalDateTime expiresAt = LocalDateTime.now().plus(PASSWORD_RESET_TTL);
        passwordResetTokens.entrySet().removeIf(entry -> entry.getValue().userId().equals(user.id));
        passwordResetTokens.put(token, new PasswordResetToken(user.id, expiresAt));
        return new ForgotPasswordResponse(token, expiresAt);
    }

    @Transactional
    public void resetForgottenPassword(ResetForgottenPasswordRequest request) {
        cleanupExpiredPasswordResetTokens();
        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new BusinessException("Confirm password does not match", "PASSWORD_CONFIRM_MISMATCH", HttpStatus.BAD_REQUEST);
        }
        PasswordResetToken resetToken = passwordResetTokens.get(request.token());
        if (resetToken == null || resetToken.expiresAt().isBefore(LocalDateTime.now())) {
            passwordResetTokens.remove(request.token());
            throw new BusinessException("Password reset token is invalid or expired", "PASSWORD_RESET_TOKEN_INVALID", HttpStatus.BAD_REQUEST);
        }
        User user = users.findById(resetToken.userId())
                .orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        if (user.status != UserStatus.ACTIVE) {
            throw new UnauthorizedException("Account is not active", "AUTH_ACCOUNT_INACTIVE");
        }
        user.passwordHash = passwordEncoder.encode(request.newPassword());
        user.mustChangePassword = false;
        passwordResetTokens.remove(request.token());
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new BusinessException("Confirm password does not match", "PASSWORD_CONFIRM_MISMATCH", HttpStatus.BAD_REQUEST);
        }
        User user = users.findById(currentUser.userId()).orElseThrow();
        if (!passwordEncoder.matches(request.oldPassword(), user.passwordHash)) {
            throw new UnauthorizedException("Old password is incorrect", "AUTH_INVALID_CREDENTIALS");
        }
        user.passwordHash = passwordEncoder.encode(request.newPassword());
        user.mustChangePassword = false;
    }

    @Transactional
    public UserResponse createTenantAccount(CreateTenantAccountRequest request) {
        users.findByUsername(request.username()).ifPresent(u -> {
            throw new BusinessException("Username already exists", "USER_USERNAME_EXISTS");
        });
        if (users.existsByEmailIgnoreCase(request.email().trim())) {
            throw new BusinessException("Email already exists", "USER_EMAIL_EXISTS");
        }
        if (users.existsByPhone(request.phone().trim())) {
            throw new BusinessException("Phone number already exists", "USER_PHONE_EXISTS");
        }
        if (tenantProfiles.existsByIdentityNumberIgnoreCase(request.identityNumber().trim())) {
            throw new BusinessException("Identity number already exists", "TENANT_IDENTITY_EXISTS");
        }
        Role tenant = roles.findByCode("TENANT").orElseThrow(() -> new NotFoundException("Tenant role not found", "ROLE_NOT_FOUND"));
        User user = new User();
        user.username = request.username();
        user.passwordHash = passwordEncoder.encode(request.temporaryPassword());
        user.role = tenant;
        user.status = UserStatus.ACTIVE;
        user.mustChangePassword = true;
        user.phone = request.phone().trim();
        user.email = request.email().trim().toLowerCase(Locale.ROOT);
        return UserResponse.from(users.save(user));
    }

    public Page<UserResponse> users(Pageable pageable) {
        return users.findAll(pageable).map(UserResponse::from);
    }

    @Transactional
    public UserResponse lock(Long id) {
        User user = users.findById(id).orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        user.status = UserStatus.LOCKED;
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse unlock(Long id) {
        User user = users.findById(id).orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        user.status = UserStatus.ACTIVE;
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse resetPassword(Long id, ResetPasswordRequest request) {
        User user = users.findById(id).orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        user.passwordHash = passwordEncoder.encode(request.newPassword());
        user.mustChangePassword = true;
        return UserResponse.from(user);
    }

    private Optional<User> findUserForPasswordReset(String usernameOrEmail) {
        String value = usernameOrEmail == null ? "" : usernameOrEmail.trim();
        if (value.isEmpty()) {
            return Optional.empty();
        }
        Optional<User> byUsername = users.findByUsername(value);
        if (byUsername.isPresent()) {
            return byUsername;
        }
        return users.findByEmail(value);
    }

    private String generatePasswordResetToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private void cleanupExpiredPasswordResetTokens() {
        LocalDateTime now = LocalDateTime.now();
        passwordResetTokens.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
    }

    private record PasswordResetToken(Long userId, LocalDateTime expiresAt) {
    }
}
