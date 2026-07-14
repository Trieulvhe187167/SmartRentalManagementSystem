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
import com.example.rentalmanagement.auth.PasswordResetToken;
import com.example.rentalmanagement.auth.repository.PasswordResetTokenRepository;
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
    private final PasswordResetTokenRepository passwordResetTokens;
    private final PasswordResetDeliveryService passwordResetDelivery;
    private final java.security.SecureRandom secureRandom = new java.security.SecureRandom();

    public AuthService(
            UserRepository users,
            RoleRepository roles,
            TenantProfileRepository tenantProfiles,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider tokens,
            CurrentUser currentUser,
            PasswordResetTokenRepository passwordResetTokens,
            PasswordResetDeliveryService passwordResetDelivery
    ) {
        this.users = users;
        this.roles = roles;
        this.tenantProfiles = tenantProfiles;
        this.passwordEncoder = passwordEncoder;
        this.tokens = tokens;
        this.currentUser = currentUser;
        this.passwordResetTokens = passwordResetTokens;
        this.passwordResetDelivery = passwordResetDelivery;
    }

    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = users.findByUsername(request.username())
                .orElseThrow(() -> new UnauthorizedException("Username or password is incorrect", "AUTH_INVALID_CREDENTIALS"));
        if (user.getStatus() == UserStatus.LOCKED) {
            throw new UnauthorizedException("Account is locked", "AUTH_ACCOUNT_LOCKED");
        }
        if (user.getStatus() == UserStatus.INACTIVE) {
            throw new UnauthorizedException("Account is inactive", "AUTH_ACCOUNT_INACTIVE");
        }
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Username or password is incorrect", "AUTH_INVALID_CREDENTIALS");
        }
        user.setLastLoginAt(LocalDateTime.now());
        return new LoginResponse(
                tokens.generate(user),
                "Bearer",
                tokens.expiresInSeconds(),
                user.getId(),
                user.getUsername(),
                user.roleName(),
                user.isMustChangePassword()
        );
    }

    public UserResponse me() {
        User user = currentUser.requireUser();
        TenantProfile profile = tenantProfiles.findByUserId(user.id).orElse(null);
        return UserResponse.from(user, profile);
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        cleanupExpiredPasswordResetTokens();
        User user = findUserForPasswordReset(request.usernameOrEmail())
                .orElseThrow(() -> new NotFoundException("Account or email was not found", "PASSWORD_RESET_ACCOUNT_NOT_FOUND"));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new BusinessException(
                    "Account is not active",
                    "PASSWORD_RESET_ACCOUNT_INACTIVE",
                    HttpStatus.BAD_REQUEST
            );
        }
        String rawToken = generatePasswordResetToken();
        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.user = user;
        resetToken.tokenHash = hashPasswordResetToken(rawToken);
        resetToken.expiresAt = LocalDateTime.now().plus(PASSWORD_RESET_TTL);

        passwordResetTokens.deleteActiveByUserId(user.getId());
        passwordResetTokens.save(resetToken);
        passwordResetDelivery.send(user, rawToken);
    }

    @Transactional
    public void resetForgottenPassword(ResetForgottenPasswordRequest request) {
        cleanupExpiredPasswordResetTokens();
        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new BusinessException("Confirm password does not match", "PASSWORD_CONFIRM_MISMATCH", HttpStatus.BAD_REQUEST);
        }
        validatePasswordPolicy(request.newPassword());
        PasswordResetToken resetToken = passwordResetTokens
                .findByTokenHash(hashPasswordResetToken(request.token()))
                .orElseThrow(() -> new BusinessException(
                        "Password reset token is invalid or expired",
                        "PASSWORD_RESET_TOKEN_INVALID",
                        HttpStatus.BAD_REQUEST
                ));
        if (resetToken.usedAt != null || resetToken.expiresAt.isBefore(LocalDateTime.now())) {
            throw new BusinessException("Password reset token is invalid or expired", "PASSWORD_RESET_TOKEN_INVALID", HttpStatus.BAD_REQUEST);
        }
        User user = users.findById(resetToken.user.getId())
                .orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new UnauthorizedException("Account is not active", "AUTH_ACCOUNT_INACTIVE");
        }
        if (passwordEncoder.matches(request.newPassword(), user.getPasswordHash())) {
            throw new BusinessException(
                    "New password must be different from the current password",
                    "PASSWORD_MUST_BE_DIFFERENT",
                    HttpStatus.BAD_REQUEST
            );
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        user.setMustChangePassword(false);
        resetToken.usedAt = LocalDateTime.now();
        passwordResetTokens.saveAndFlush(resetToken);
        passwordResetTokens.deleteActiveByUserId(user.id);
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new BusinessException("Confirm password does not match", "PASSWORD_CONFIRM_MISMATCH", HttpStatus.BAD_REQUEST);
        }
        validatePasswordPolicy(request.newPassword());
        User user = users.findById(currentUser.userId()).orElseThrow();
        if (!passwordEncoder.matches(request.oldPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException("Old password is incorrect", "AUTH_INVALID_CREDENTIALS");
        }
        if (passwordEncoder.matches(request.newPassword(), user.getPasswordHash())) {
            throw new BusinessException(
                    "New password must be different from the current password",
                    "PASSWORD_MUST_BE_DIFFERENT",
                    HttpStatus.BAD_REQUEST
            );
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        user.setMustChangePassword(false);
    }

    @Transactional
    public UserResponse createTenantAccount(CreateTenantAccountRequest request) {
        users.findByUsername(request.username()).ifPresent(u -> {
            throw new BusinessException("Username already exists", "USER_USERNAME_EXISTS");
        });
        Role tenant = roles.findByCode("TENANT").orElseThrow(() -> new NotFoundException("Tenant role not found", "ROLE_NOT_FOUND"));
        User user = new User();
        user.username = request.username();
        user.passwordHash = passwordEncoder.encode(request.temporaryPassword());
        user.role = tenant;
        user.status = UserStatus.ACTIVE;
        user.mustChangePassword = true;
        user.phone = request.phone();
        user.email = request.email();
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

    @Transactional
    public UserResponse updateUsername(Long id, UpdateUsernameRequest request) {
        User user = users.findById(id).orElseThrow(() -> new NotFoundException("User not found", "USER_NOT_FOUND"));
        String username = request.username().trim();
        users.findByUsername(username)
                .filter(existing -> !existing.id.equals(user.id))
                .ifPresent(existing -> {
                    throw new BusinessException("Username already exists", "USER_USERNAME_EXISTS");
                });
        user.username = username;
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

    private String hashPasswordResetToken(String rawToken) {
        try {
            byte[] digest = java.security.MessageDigest.getInstance("SHA-256")
                    .digest(rawToken.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (java.security.NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 is not available", ex);
        }
    }

    private void validatePasswordPolicy(String password) {
        boolean validLength = password != null && password.length() >= 8 && password.length() <= 72;
        boolean hasLetter = password != null && password.codePoints().anyMatch(Character::isLetter);
        boolean hasDigit = password != null && password.codePoints().anyMatch(Character::isDigit);
        if (!validLength || !hasLetter || !hasDigit) {
            throw new BusinessException(
                    "Password must be 8-72 characters and contain at least one letter and one number",
                    "PASSWORD_POLICY_INVALID",
                    HttpStatus.BAD_REQUEST
            );
        }
    }

    private void cleanupExpiredPasswordResetTokens() {
        passwordResetTokens.deleteByExpiresAtBefore(LocalDateTime.now());
    }
}
