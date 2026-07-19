ALTER TABLE users
    ADD COLUMN avatar_data LONGTEXT NULL AFTER email;

CREATE TABLE email_change_verifications (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id     BIGINT UNSIGNED NOT NULL,
    new_email   VARCHAR(150) NOT NULL,
    code_hash   CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    expires_at  DATETIME(6) NOT NULL,
    attempts    INT NOT NULL DEFAULT 0,
    used_at     DATETIME(6) NULL,
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    INDEX idx_email_change_user (user_id, used_at),
    INDEX idx_email_change_expiry (expires_at),
    CONSTRAINT fk_email_change_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;
