package com.example.rentalmanagement.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ResetForgottenPasswordRequest(
        @NotBlank String token,
        @NotBlank @Size(min = 8, max = 72) String newPassword,
        @NotBlank String confirmPassword
) {
}
