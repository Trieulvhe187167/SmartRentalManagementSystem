package com.example.rentalmanagement.auth.controller;

import com.example.rentalmanagement.auth.PasswordResetToken;
import com.example.rentalmanagement.auth.repository.PasswordResetTokenRepository;
import com.example.rentalmanagement.auth.service.PasswordResetDeliveryService;
import com.example.rentalmanagement.common.enums.UserStatus;
import com.example.rentalmanagement.user.Role;
import com.example.rentalmanagement.user.User;
import com.example.rentalmanagement.user.repository.RoleRepository;
import com.example.rentalmanagement.user.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthControllerIntegrationTest {
    private static final String USERNAME = "auth-api-tenant";
    private static final String EMAIL = "auth-api-tenant@example.com";
    private static final String PASSWORD = "Tenant123";

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository users;
    @Autowired RoleRepository roles;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired PasswordResetTokenRepository passwordResetTokens;
    @Autowired EntityManager entityManager;

    @MockBean PasswordResetDeliveryService passwordResetDelivery;

    private User tenant;

    @BeforeEach
    void createTenant() {
        Role tenantRole = roles.findByCode("TENANT").orElseThrow();
        tenant = new User();
        tenant.username = USERNAME;
        tenant.email = EMAIL;
        tenant.passwordHash = passwordEncoder.encode(PASSWORD);
        tenant.role = tenantRole;
        tenant.status = UserStatus.ACTIVE;
        tenant.mustChangePassword = false;
        tenant = users.saveAndFlush(tenant);
    }

    @Test
    void loginReturnsTenantRoleAndJwt() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username").value(USERNAME))
                .andExpect(jsonPath("$.data.role").value("TENANT"))
                .andExpect(jsonPath("$.data.accessToken", not(blankOrNullString())));
    }

    @Test
    void meReturnsAuthenticatedUserAndRejectsAnonymousRequest() throws Exception {
        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", bearerToken(PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username").value(USERNAME))
                .andExpect(jsonPath("$.data.role").value("TENANT"));
    }

    @Test
    void changePasswordValidatesOldPasswordAndAllowsNewLogin() throws Exception {
        String token = login(PASSWORD);

        mockMvc.perform(put("/api/v1/auth/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "oldPassword": "Wrong123",
                                  "newPassword": "Changed123",
                                  "confirmPassword": "Changed123"
                                }
                                """))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(put("/api/v1/auth/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "oldPassword": "Tenant123",
                                  "newPassword": "Changed123",
                                  "confirmPassword": "Changed123"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("Changed123")))
                .andExpect(status().isOk());
    }

    @Test
    void forgotPasswordValidatesAccountAndNeverReturnsToken() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"missing@example.com\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("PASSWORD_RESET_ACCOUNT_NOT_FOUND"));

        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"" + EMAIL + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").doesNotExist())
                .andExpect(content().string(not(org.hamcrest.Matchers.containsString("resetToken"))));
    }

    @Test
    void forgotPasswordStillWorksAfterExpiredTokenCleanup() throws Exception {
        PasswordResetToken expiredToken = new PasswordResetToken();
        expiredToken.user = tenant;
        expiredToken.tokenHash = "a".repeat(64);
        expiredToken.expiresAt = LocalDateTime.now().minusMinutes(1);
        passwordResetTokens.saveAndFlush(expiredToken);
        entityManager.clear();

        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"" + EMAIL + "\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void resetPasswordUsesDeliveredTokenOnceAndAllowsNewLogin() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"" + USERNAME + "\"}"))
                .andExpect(status().isOk());

        ArgumentCaptor<String> tokenCaptor = ArgumentCaptor.forClass(String.class);
        verify(passwordResetDelivery).send(any(User.class), tokenCaptor.capture());
        String rawToken = tokenCaptor.getValue();
        String resetBody = objectMapper.writeValueAsString(new ResetBody(rawToken, "Reset1234", "Reset1234"));
        entityManager.flush();
        entityManager.clear();

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resetBody))
                .andExpect(status().isOk());
        entityManager.flush();
        entityManager.clear();

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resetBody))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("PASSWORD_RESET_TOKEN_INVALID"));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("Reset1234")))
                .andExpect(status().isOk());
    }

    private String bearerToken(String password) throws Exception {
        return "Bearer " + login(password);
    }

    private String login(String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(password)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return response.path("data").path("accessToken").asText();
    }

    private String loginBody(String password) throws Exception {
        return objectMapper.writeValueAsString(new LoginBody(USERNAME, password));
    }

    private record LoginBody(String username, String password) {
    }

    private record ResetBody(String token, String newPassword, String confirmPassword) {
    }
}
