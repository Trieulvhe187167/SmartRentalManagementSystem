package com.example.rentalmanagement.auth.service;

import com.example.rentalmanagement.auth.PasswordResetToken;
import com.example.rentalmanagement.auth.dto.ChangePasswordRequest;
import com.example.rentalmanagement.auth.dto.ForgotPasswordRequest;
import com.example.rentalmanagement.auth.dto.ResetForgottenPasswordRequest;
import com.example.rentalmanagement.auth.repository.PasswordResetTokenRepository;
import com.example.rentalmanagement.common.enums.UserStatus;
import com.example.rentalmanagement.common.exception.BusinessException;
import com.example.rentalmanagement.common.exception.NotFoundException;
import com.example.rentalmanagement.common.security.CurrentUser;
import com.example.rentalmanagement.common.security.JwtTokenProvider;
import com.example.rentalmanagement.tenant.repository.TenantProfileRepository;
import com.example.rentalmanagement.user.User;
import com.example.rentalmanagement.user.repository.RoleRepository;
import com.example.rentalmanagement.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    @Mock UserRepository users;
    @Mock RoleRepository roles;
    @Mock TenantProfileRepository tenantProfiles;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtTokenProvider jwtTokenProvider;
    @Mock CurrentUser currentUser;
    @Mock PasswordResetTokenRepository passwordResetTokens;
    @Mock PasswordResetDeliveryService passwordResetDelivery;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(
                users,
                roles,
                tenantProfiles,
                passwordEncoder,
                jwtTokenProvider,
                currentUser,
                passwordResetTokens,
                passwordResetDelivery
        );
    }

    @Test
    void forgotPasswordStoresOnlyTokenHashAndDeliversRawToken() throws Exception {
        User user = activeUser();
        when(users.findByUsername("tenant01")).thenReturn(Optional.of(user));
        when(passwordResetTokens.save(any(PasswordResetToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        authService.forgotPassword(new ForgotPasswordRequest("tenant01"));

        ArgumentCaptor<PasswordResetToken> storedCaptor = ArgumentCaptor.forClass(PasswordResetToken.class);
        ArgumentCaptor<String> rawCaptor = ArgumentCaptor.forClass(String.class);
        verify(passwordResetTokens).save(storedCaptor.capture());
        verify(passwordResetDelivery).send(eq(user), rawCaptor.capture());

        String rawToken = rawCaptor.getValue();
        PasswordResetToken stored = storedCaptor.getValue();
        assertNotNull(rawToken);
        assertFalse(rawToken.isBlank());
        assertNotEquals(rawToken, stored.tokenHash);
        assertEquals(sha256(rawToken), stored.tokenHash);
        assertEquals(user, stored.user);
    }

    @Test
    void forgotPasswordRejectsUnknownAccount() {
        when(users.findByUsername("missing@example.com")).thenReturn(Optional.empty());
        when(users.findByEmail("missing@example.com")).thenReturn(Optional.empty());

        assertThrows(
                NotFoundException.class,
                () -> authService.forgotPassword(new ForgotPasswordRequest("missing@example.com"))
        );
    }

    @Test
    void resetPasswordMarksTokenUsedAndInvalidatesOtherTokens() {
        User user = activeUser();
        String rawToken = "valid-reset-token";
        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.user = user;
        resetToken.tokenHash = sha256(rawToken);
        resetToken.expiresAt = LocalDateTime.now().plusMinutes(10);

        when(passwordResetTokens.findByTokenHash(resetToken.tokenHash))
                .thenReturn(Optional.of(resetToken));
        when(users.findById(user.id)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("NewPassword123", user.passwordHash)).thenReturn(false);
        when(passwordEncoder.encode("NewPassword123")).thenReturn("new-hash");

        authService.resetForgottenPassword(
                new ResetForgottenPasswordRequest(rawToken, "NewPassword123", "NewPassword123")
        );

        assertEquals("new-hash", user.passwordHash);
        assertNotNull(resetToken.usedAt);
        verify(passwordResetTokens).saveAndFlush(resetToken);
        verify(passwordResetTokens).deleteActiveByUserId(user.id);
    }

    @Test
    void changePasswordRejectsCurrentPasswordAsNewPassword() {
        User user = activeUser();
        when(currentUser.userId()).thenReturn(user.id);
        when(users.findById(user.id)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("Current123", user.passwordHash)).thenReturn(true);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> authService.changePassword(
                        new ChangePasswordRequest("Current123", "Current123", "Current123")
                )
        );

        assertEquals("PASSWORD_MUST_BE_DIFFERENT", exception.errorCode);
    }

    @Test
    void changePasswordRejectsPasswordWithoutNumber() {
        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> authService.changePassword(
                        new ChangePasswordRequest("Current123", "OnlyLetters", "OnlyLetters")
                )
        );

        assertEquals("PASSWORD_POLICY_INVALID", exception.errorCode);
    }

    private User activeUser() {
        User user = new User();
        user.id = 10L;
        user.username = "tenant01";
        user.email = "tenant01@example.com";
        user.passwordHash = "current-hash";
        user.status = UserStatus.ACTIVE;
        return user;
    }

    private String sha256(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
    }
}
