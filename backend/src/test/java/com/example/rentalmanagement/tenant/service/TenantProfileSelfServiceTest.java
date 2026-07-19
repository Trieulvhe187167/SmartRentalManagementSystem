package com.example.rentalmanagement.tenant.service;

import com.example.rentalmanagement.auth.EmailChangeVerification;
import com.example.rentalmanagement.auth.repository.EmailChangeVerificationRepository;
import com.example.rentalmanagement.auth.service.EmailChangeDeliveryService;
import com.example.rentalmanagement.tenant.TenantProfile;
import com.example.rentalmanagement.tenant.dto.EmailChangeRequest;
import com.example.rentalmanagement.tenant.dto.EmailChangeStartResponse;
import com.example.rentalmanagement.tenant.dto.EmailChangeVerifyRequest;
import com.example.rentalmanagement.tenant.dto.TenantSelfProfileUpdateRequest;
import com.example.rentalmanagement.tenant.repository.TenantProfileRepository;
import com.example.rentalmanagement.user.User;
import com.example.rentalmanagement.user.dto.UserResponse;
import com.example.rentalmanagement.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TenantProfileSelfServiceTest {
    @Mock UserRepository users;
    @Mock TenantProfileRepository tenants;
    @Mock EmailChangeVerificationRepository verifications;
    @Mock EmailChangeDeliveryService emailDelivery;

    private TenantProfileSelfService service;
    private User user;
    private TenantProfile profile;

    @BeforeEach
    void setUp() {
        service = new TenantProfileSelfService(users, tenants, verifications, emailDelivery);
        user = new User();
        user.id = 7L;
        user.username = "tenant01";
        profile = new TenantProfile();
        profile.user = user;
        profile.fullName = "Nguyễn Minh Anh";
        profile.permanentAddress = "Thủ Đức";
        when(tenants.findByUserId(7L)).thenReturn(Optional.of(profile));
    }

    @Test
    void updatesEditableContactFields() {
        when(users.findByPhone("0901000001")).thenReturn(Optional.empty());

        UserResponse result = service.updateProfile(
                7L,
                new TenantSelfProfileUpdateRequest(
                        "0901000001",
                        "Thành phố Thủ Đức",
                        "data:image/png;base64,aGVsbG8="
                )
        );

        assertEquals("0901000001", result.phone());
        assertEquals("Thành phố Thủ Đức", result.address());
        assertEquals("data:image/png;base64,aGVsbG8=", result.avatarData());
    }

    @Test
    void addsFirstEmailWithoutVerification() {
        when(users.findByEmail("tenant@example.com")).thenReturn(Optional.empty());

        EmailChangeStartResponse result = service.requestEmailChange(
                7L,
                new EmailChangeRequest("Tenant@Example.com")
        );

        assertFalse(result.requiresVerification());
        assertEquals("tenant@example.com", user.email);
        verify(emailDelivery, never()).send(any(), any());
    }

    @Test
    void changesExistingEmailOnlyAfterCorrectOtp() {
        user.email = "old@example.com";
        when(users.findByEmail("new@example.com")).thenReturn(Optional.empty());
        ArgumentCaptor<EmailChangeVerification> verificationCaptor =
                ArgumentCaptor.forClass(EmailChangeVerification.class);
        ArgumentCaptor<String> codeCaptor = ArgumentCaptor.forClass(String.class);
        when(verifications.save(verificationCaptor.capture()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        EmailChangeStartResponse start = service.requestEmailChange(
                7L,
                new EmailChangeRequest("new@example.com")
        );
        verify(emailDelivery).send(eq("new@example.com"), codeCaptor.capture());
        when(verifications.findTopByUserIdAndNewEmailAndUsedAtIsNullOrderByCreatedAtDesc(
                7L,
                "new@example.com"
        )).thenReturn(Optional.of(verificationCaptor.getValue()));

        UserResponse result = service.verifyEmailChange(
                7L,
                new EmailChangeVerifyRequest("new@example.com", codeCaptor.getValue())
        );

        assertTrue(start.requiresVerification());
        assertEquals("new@example.com", result.email());
        assertEquals("new@example.com", user.email);
    }
}
