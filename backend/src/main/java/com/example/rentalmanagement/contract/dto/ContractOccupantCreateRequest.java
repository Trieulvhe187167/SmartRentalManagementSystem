package com.example.rentalmanagement.contract.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record ContractOccupantCreateRequest(
        @NotBlank @Size(max = 150) String fullName,
        LocalDate dateOfBirth,
        @Size(max = 20) String phone,
        @Size(max = 20) String identityType,
        @Size(max = 30) String identityNumber,
        @Size(max = 500) String permanentAddress,
        @NotBlank @Size(max = 100) String relationshipToPrimary,
        @NotNull LocalDate moveInDate
) {
}
