package com.example.rentalmanagement.tenant.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TenantSelfProfileUpdateRequest(
        @Size(max = 20) String phone,
        @NotBlank @Size(max = 500) String permanentAddress,
        @Size(max = 2800000) String avatarData
) {
}
