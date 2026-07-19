package com.example.rentalmanagement.tenant.service;

import com.example.rentalmanagement.auth.EmailChangeVerification;
import com.example.rentalmanagement.auth.repository.EmailChangeVerificationRepository;
import com.example.rentalmanagement.auth.service.EmailChangeDeliveryService;
import com.example.rentalmanagement.common.exception.BusinessException;
import com.example.rentalmanagement.common.exception.NotFoundException;
import com.example.rentalmanagement.tenant.TenantProfile;
import com.example.rentalmanagement.tenant.dto.EmailChangeRequest;
import com.example.rentalmanagement.tenant.dto.EmailChangeStartResponse;
import com.example.rentalmanagement.tenant.dto.EmailChangeVerifyRequest;
import com.example.rentalmanagement.tenant.dto.TenantSelfProfileUpdateRequest;
import com.example.rentalmanagement.tenant.repository.TenantProfileRepository;
import com.example.rentalmanagement.user.User;
import com.example.rentalmanagement.user.dto.UserResponse;
import com.example.rentalmanagement.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Optional;

@Service
public class TenantProfileSelfService {
    private static final int MAX_AVATAR_BYTES = 2 * 1024 * 1024;
    private static final int MAX_CODE_ATTEMPTS = 5;
    private static final String AVATAR_PREFIX_PATTERN = "^data:image/(png|jpeg|webp);base64,";

    private final UserRepository users;
    private final TenantProfileRepository tenants;
    private final EmailChangeVerificationRepository verifications;
    private final EmailChangeDeliveryService emailDelivery;
    private final SecureRandom secureRandom = new SecureRandom();

    public TenantProfileSelfService(
            UserRepository users,
            TenantProfileRepository tenants,
            EmailChangeVerificationRepository verifications,
            EmailChangeDeliveryService emailDelivery
    ) {
        this.users = users;
        this.tenants = tenants;
        this.verifications = verifications;
        this.emailDelivery = emailDelivery;
    }

    @Transactional
    public UserResponse updateProfile(Long userId, TenantSelfProfileUpdateRequest request) {
        TenantProfile profile = requireProfile(userId);
        User user = profile.user;
        String phone = normalizeNullable(request.phone());

        if (phone != null && !phone.matches("^[+]?[0-9]{9,15}$")) {
            throw new BusinessException(
                    "Phone number must contain 9-15 digits",
                    "PROFILE_PHONE_INVALID",
                    HttpStatus.BAD_REQUEST
            );
        }
        if (phone != null) {
            users.findByPhone(phone)
                    .filter(existing -> !existing.id.equals(user.id))
                    .ifPresent(existing -> {
                        throw new BusinessException("Phone already exists", "USER_PHONE_EXISTS");
                    });
        }

        user.phone = phone;
        profile.permanentAddress = request.permanentAddress().trim();
        if (request.avatarData() != null) {
            user.avatarData = validateAvatar(request.avatarData());
        }
        return UserResponse.from(user, profile);
    }

    @Transactional
    public EmailChangeStartResponse requestEmailChange(Long userId, EmailChangeRequest request) {
        TenantProfile profile = requireProfile(userId);
        User user = profile.user;
        String newEmail = normalizeEmail(request.email());
        String currentEmail = normalizeNullable(user.email);

        ensureEmailAvailable(newEmail, user.id);
        verifications.deleteByExpiresAtBefore(LocalDateTime.now());
        verifications.deleteActiveByUserId(user.id);

        if (currentEmail == null) {
            user.email = newEmail;
            return new EmailChangeStartResponse(
                    false,
                    newEmail,
                    "Email was added successfully",
                    UserResponse.from(user, profile)
            );
        }
        if (currentEmail.equalsIgnoreCase(newEmail)) {
            return new EmailChangeStartResponse(
                    false,
                    currentEmail,
                    "Email is unchanged",
                    UserResponse.from(user, profile)
            );
        }

        String code = String.format(Locale.ROOT, "%06d", secureRandom.nextInt(1_000_000));
        EmailChangeVerification verification = new EmailChangeVerification();
        verification.user = user;
        verification.newEmail = newEmail;
        verification.codeHash = hash(code);
        verification.expiresAt = LocalDateTime.now().plusMinutes(10);
        verifications.save(verification);
        emailDelivery.send(newEmail, code);

        return new EmailChangeStartResponse(
                true,
                newEmail,
                "Verification code was sent to the new email",
                null
        );
    }

    @Transactional(noRollbackFor = BusinessException.class)
    public UserResponse verifyEmailChange(Long userId, EmailChangeVerifyRequest request) {
        TenantProfile profile = requireProfile(userId);
        User user = profile.user;
        String newEmail = normalizeEmail(request.email());
        EmailChangeVerification verification = verifications
                .findTopByUserIdAndNewEmailAndUsedAtIsNullOrderByCreatedAtDesc(user.id, newEmail)
                .orElseThrow(() -> new NotFoundException(
                        "Email verification request was not found",
                        "EMAIL_CHANGE_REQUEST_NOT_FOUND"
                ));

        if (verification.expiresAt.isBefore(LocalDateTime.now())) {
            verification.usedAt = LocalDateTime.now();
            throw new BusinessException(
                    "Verification code has expired",
                    "EMAIL_CHANGE_CODE_EXPIRED",
                    HttpStatus.BAD_REQUEST
            );
        }
        if (verification.attempts >= MAX_CODE_ATTEMPTS) {
            verification.usedAt = LocalDateTime.now();
            throw new BusinessException(
                    "Too many invalid verification attempts",
                    "EMAIL_CHANGE_TOO_MANY_ATTEMPTS",
                    HttpStatus.BAD_REQUEST
            );
        }
        if (!MessageDigest.isEqual(
                verification.codeHash.getBytes(StandardCharsets.US_ASCII),
                hash(request.code()).getBytes(StandardCharsets.US_ASCII)
        )) {
            verification.attempts++;
            throw new BusinessException(
                    "Verification code is incorrect",
                    "EMAIL_CHANGE_CODE_INVALID",
                    HttpStatus.BAD_REQUEST
            );
        }

        ensureEmailAvailable(newEmail, user.id);
        user.email = newEmail;
        verification.usedAt = LocalDateTime.now();
        return UserResponse.from(user, profile);
    }

    private TenantProfile requireProfile(Long userId) {
        return tenants.findByUserId(userId)
                .orElseThrow(() -> new NotFoundException("Tenant profile not found", "TENANT_NOT_FOUND"));
    }

    private void ensureEmailAvailable(String email, Long userId) {
        users.findByEmail(email)
                .filter(existing -> !existing.id.equals(userId))
                .ifPresent(existing -> {
                    throw new BusinessException("Email already exists", "USER_EMAIL_EXISTS");
                });
    }

    private String validateAvatar(String avatarData) {
        String value = avatarData.trim();
        if (value.isEmpty()) {
            return null;
        }
        if (!value.matches("(?s)" + AVATAR_PREFIX_PATTERN + ".+")) {
            throw new BusinessException(
                    "Avatar must be a PNG, JPEG, or WebP image",
                    "PROFILE_AVATAR_FORMAT_INVALID",
                    HttpStatus.BAD_REQUEST
            );
        }
        int separator = value.indexOf(',');
        try {
            byte[] decoded = Base64.getDecoder().decode(value.substring(separator + 1));
            if (decoded.length > MAX_AVATAR_BYTES) {
                throw new BusinessException(
                        "Avatar must not exceed 2 MB",
                        "PROFILE_AVATAR_TOO_LARGE",
                        HttpStatus.BAD_REQUEST
                );
            }
        } catch (IllegalArgumentException ex) {
            throw new BusinessException(
                    "Avatar data is invalid",
                    "PROFILE_AVATAR_DATA_INVALID",
                    HttpStatus.BAD_REQUEST
            );
        }
        return value;
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeNullable(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 is not available", ex);
        }
    }
}
