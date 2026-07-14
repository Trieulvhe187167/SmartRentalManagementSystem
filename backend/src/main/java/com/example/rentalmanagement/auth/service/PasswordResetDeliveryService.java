package com.example.rentalmanagement.auth.service;

import com.example.rentalmanagement.common.exception.BusinessException;
import com.example.rentalmanagement.user.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class PasswordResetDeliveryService {
    private static final Logger log = LoggerFactory.getLogger(PasswordResetDeliveryService.class);

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final boolean mailEnabled;
    private final String frontendResetUrl;
    private final String fromAddress;

    public PasswordResetDeliveryService(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.password-reset.mail-enabled:false}") boolean mailEnabled,
            @Value("${app.password-reset.frontend-reset-url:http://localhost:3000/#/reset-password}") String frontendResetUrl,
            @Value("${app.password-reset.from-address:no-reply@lumina.local}") String fromAddress
    ) {
        this.mailSenderProvider = mailSenderProvider;
        this.mailEnabled = mailEnabled;
        this.frontendResetUrl = frontendResetUrl;
        this.fromAddress = fromAddress;
    }

    public void send(User user, String rawToken) {
        String email = user.getEmail();
        if (email == null || email.isBlank()) {
            throw new BusinessException(
                    "Account does not have a registered email address",
                    "PASSWORD_RESET_EMAIL_MISSING",
                    HttpStatus.BAD_REQUEST
            );
        }

        String link = frontendResetUrl + "?token="
                + URLEncoder.encode(rawToken, StandardCharsets.UTF_8);

        if (!mailEnabled) {
            log.warn("Password reset mail is disabled. Development reset link for {}: {}", user.getUsername(), link);
            return;
        }

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null) {
            throw new BusinessException(
                    "Password reset email service is not configured",
                    "PASSWORD_RESET_MAIL_NOT_CONFIGURED",
                    HttpStatus.SERVICE_UNAVAILABLE
            );
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(email);
        message.setSubject("Lumina Resident - Dat lai mat khau");
        message.setText("Mo lien ket sau de dat lai mat khau. Lien ket co hieu luc trong 15 phut:\n\n" + link);
        mailSender.send(message);
    }
}
