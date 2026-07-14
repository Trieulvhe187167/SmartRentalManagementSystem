package com.example.rentalmanagement.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import com.example.rentalmanagement.auth.validation.ValidPassword;

public record ResetForgottenPasswordRequest(
        @NotBlank String token,
        @NotBlank @ValidPassword String newPassword,
        @NotBlank @Size(max = 72) String confirmPassword
) {
}
