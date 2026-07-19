package com.example.rentalmanagement.auth;

import com.example.rentalmanagement.common.audit.IdEntity;
import com.example.rentalmanagement.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "email_change_verifications",
        indexes = {
                @Index(name = "idx_email_change_user", columnList = "user_id, used_at"),
                @Index(name = "idx_email_change_expiry", columnList = "expires_at")
        }
)
public class EmailChangeVerification extends IdEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    public User user;

    @Column(name = "new_email", nullable = false, length = 150)
    public String newEmail;

    @Column(name = "code_hash", nullable = false, length = 64)
    public String codeHash;

    @Column(name = "expires_at", nullable = false)
    public LocalDateTime expiresAt;

    @Column(nullable = false)
    public int attempts;

    @Column(name = "used_at")
    public LocalDateTime usedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    public LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
