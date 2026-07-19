package com.example.rentalmanagement.tenant.dto;

import com.example.rentalmanagement.user.dto.UserResponse;

public record EmailChangeStartResponse(
        boolean requiresVerification,
        String email,
        String message,
        UserResponse user
) {
}
