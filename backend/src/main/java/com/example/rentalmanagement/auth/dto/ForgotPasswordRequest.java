package com.example.rentalmanagement.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ForgotPasswordRequest(
        @NotBlank @Size(max = 150) String usernameOrEmail
) {
}
