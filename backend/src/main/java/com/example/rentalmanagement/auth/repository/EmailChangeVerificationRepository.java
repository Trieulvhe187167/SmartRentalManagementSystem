package com.example.rentalmanagement.auth.repository;

import com.example.rentalmanagement.auth.EmailChangeVerification;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;

public interface EmailChangeVerificationRepository extends JpaRepository<EmailChangeVerification, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<EmailChangeVerification> findTopByUserIdAndNewEmailAndUsedAtIsNullOrderByCreatedAtDesc(
            Long userId,
            String newEmail
    );

    @Modifying
    @Query("delete from EmailChangeVerification verification where verification.user.id = :userId and verification.usedAt is null")
    int deleteActiveByUserId(@Param("userId") Long userId);

    @Modifying
    @Query("delete from EmailChangeVerification verification where verification.expiresAt < :cutoff")
    int deleteByExpiresAtBefore(@Param("cutoff") LocalDateTime cutoff);
}
