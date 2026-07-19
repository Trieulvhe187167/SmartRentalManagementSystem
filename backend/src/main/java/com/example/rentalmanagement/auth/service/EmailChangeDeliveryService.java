package com.example.rentalmanagement.auth.service;

import com.example.rentalmanagement.common.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailChangeDeliveryService {
    private static final Logger log = LoggerFactory.getLogger(EmailChangeDeliveryService.class);

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final boolean mailEnabled;
    private final String fromAddress;

    public EmailChangeDeliveryService(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.email-change.mail-enabled:false}") boolean mailEnabled,
            @Value("${app.email-change.from-address:no-reply@lumina.local}") String fromAddress
    ) {
        this.mailSenderProvider = mailSenderProvider;
        this.mailEnabled = mailEnabled;
        this.fromAddress = fromAddress;
    }

    public void send(String email, String code) {
        if (!mailEnabled) {
            log.warn("Email change mail is disabled. Development verification code for {}: {}", email, code);
            return;
        }

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null) {
            throw new BusinessException(
                    "Email verification service is not configured",
                    "EMAIL_CHANGE_MAIL_NOT_CONFIGURED",
                    HttpStatus.SERVICE_UNAVAILABLE
            );
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(email);
        message.setSubject("Lumina Resident - Xac minh email moi");
        message.setText("Ma xac minh email cua ban la: " + code
                + "\n\nMa co hieu luc trong 10 phut. Khong chia se ma nay voi bat ky ai.");
        mailSender.send(message);
    }
}
