package com.example.rentalmanagement.auth.dto;

import java.time.LocalDateTime;

public record ForgotPasswordResponse(
        String resetToken,
        LocalDateTime expiresAt
) {
}
