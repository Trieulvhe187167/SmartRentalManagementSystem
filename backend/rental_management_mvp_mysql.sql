-- ============================================================
-- Rental Management MVP Database
-- DBMS: MySQL 8.0+
-- Scope: one building, ADMIN/TENANT, rooms, contracts, services,
-- meter readings, invoices, payments, maintenance, notifications.
-- ============================================================

CREATE DATABASE IF NOT EXISTS rental_management_mvp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE rental_management_mvp;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS vw_invoice_balance;
DROP VIEW IF EXISTS vw_room_current_tenant;
DROP VIEW IF EXISTS vw_active_contract_resident_count;

DROP PROCEDURE IF EXISTS sp_mark_overdue_invoices;
DROP PROCEDURE IF EXISTS sp_recalculate_invoice_payment;

DROP TRIGGER IF EXISTS trg_maintenance_requests_validate_bu;
DROP TRIGGER IF EXISTS trg_maintenance_requests_validate_bi;
DROP TRIGGER IF EXISTS trg_payments_no_delete_bd;
DROP TRIGGER IF EXISTS trg_payments_recalculate_au;
DROP TRIGGER IF EXISTS trg_payments_recalculate_ai;
DROP TRIGGER IF EXISTS trg_payments_validate_bu;
DROP TRIGGER IF EXISTS trg_payments_validate_bi;
DROP TRIGGER IF EXISTS trg_invoices_lock_readings_au;
DROP TRIGGER IF EXISTS trg_invoices_validate_bu;
DROP TRIGGER IF EXISTS trg_invoices_validate_bi;
DROP TRIGGER IF EXISTS trg_invoice_items_total_ad;
DROP TRIGGER IF EXISTS trg_invoice_items_total_au;
DROP TRIGGER IF EXISTS trg_invoice_items_total_ai;
DROP TRIGGER IF EXISTS trg_invoice_items_validate_bd;
DROP TRIGGER IF EXISTS trg_invoice_items_validate_bu;
DROP TRIGGER IF EXISTS trg_invoice_items_validate_bi;
DROP TRIGGER IF EXISTS trg_meter_readings_validate_bu;
DROP TRIGGER IF EXISTS trg_meter_readings_validate_bi;
DROP TRIGGER IF EXISTS trg_service_prices_validate_bu;
DROP TRIGGER IF EXISTS trg_service_prices_validate_bi;
DROP TRIGGER IF EXISTS trg_contract_services_validate_bu;
DROP TRIGGER IF EXISTS trg_contract_services_validate_bi;
DROP TRIGGER IF EXISTS trg_contract_occupants_validate_bu;
DROP TRIGGER IF EXISTS trg_contract_occupants_validate_bi;
DROP TRIGGER IF EXISTS trg_rooms_status_bu;
DROP TRIGGER IF EXISTS trg_contracts_room_status_au;
DROP TRIGGER IF EXISTS trg_contracts_room_status_ai;
DROP TRIGGER IF EXISTS trg_contracts_validate_bu;
DROP TRIGGER IF EXISTS trg_contracts_validate_bi;
DROP TRIGGER IF EXISTS trg_tenant_profiles_role_bu;
DROP TRIGGER IF EXISTS trg_tenant_profiles_role_bi;

DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS maintenance_updates;
DROP TABLE IF EXISTS maintenance_requests;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS meter_readings;
DROP TABLE IF EXISTS contract_services;
DROP TABLE IF EXISTS service_prices;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS contract_occupants;
DROP TABLE IF EXISTS rental_contracts;
DROP TABLE IF EXISTS occupants;
DROP TABLE IF EXISTS tenant_profiles;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS floors;
DROP TABLE IF EXISTS buildings;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. Authentication and authorization
-- ============================================================

CREATE TABLE roles (
    id              TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code            VARCHAR(20) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(255) NULL,
    created_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_roles_code UNIQUE (code),
    CONSTRAINT chk_roles_code CHECK (code IN ('ADMIN', 'TENANT'))
) ENGINE=InnoDB;

CREATE TABLE users (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_id                 TINYINT UNSIGNED NOT NULL,
    username                VARCHAR(100) NOT NULL,
    password_hash           VARCHAR(255) NOT NULL,
    phone                   VARCHAR(20) NULL,
    email                   VARCHAR(150) NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    must_change_password    BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at           DATETIME(6) NULL,
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by              BIGINT UNSIGNED NULL,
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_phone UNIQUE (phone),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id),
    CONSTRAINT fk_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'LOCKED', 'INACTIVE')),
    CONSTRAINT chk_users_deleted_at CHECK (
        (is_deleted = FALSE AND deleted_at IS NULL)
        OR (is_deleted = TRUE AND deleted_at IS NOT NULL)
    )
) ENGINE=InnoDB;

-- ============================================================
-- 2. Building, floor and room
-- ============================================================

CREATE TABLE buildings (
    id                              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                            VARCHAR(50) NOT NULL,
    name                            VARCHAR(150) NOT NULL,
    address                         VARCHAR(500) NOT NULL,
    phone                           VARCHAR(20) NULL,
    bank_name                       VARCHAR(150) NULL,
    bank_account_number             VARCHAR(50) NULL,
    bank_account_name               VARCHAR(150) NULL,
    bank_transfer_content_template  VARCHAR(255) NULL,
    status                          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at                      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by                      BIGINT UNSIGNED NULL,
    updated_at                      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                              ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by                      BIGINT UNSIGNED NULL,
    is_deleted                      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at                      DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_buildings_code UNIQUE (code),
    CONSTRAINT fk_buildings_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_buildings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_buildings_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB;

CREATE TABLE floors (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    building_id     BIGINT UNSIGNED NOT NULL,
    floor_number    INT NOT NULL,
    name            VARCHAR(100) NULL,
    description     VARCHAR(255) NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by      BIGINT UNSIGNED NULL,
    updated_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                              ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by      BIGINT UNSIGNED NULL,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_floors_building_number UNIQUE (building_id, floor_number),
    CONSTRAINT uq_floors_id_building UNIQUE (id, building_id),
    CONSTRAINT fk_floors_building FOREIGN KEY (building_id) REFERENCES buildings(id),
    CONSTRAINT fk_floors_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_floors_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_floors_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB;

CREATE TABLE rooms (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    building_id         BIGINT UNSIGNED NOT NULL,
    floor_id            BIGINT UNSIGNED NOT NULL,
    room_number         VARCHAR(30) NOT NULL,
    area_m2             DECIMAL(8,2) NOT NULL,
    default_rent        DECIMAL(18,2) NOT NULL,
    default_deposit     DECIMAL(18,2) NOT NULL DEFAULT 0,
    max_occupants       SMALLINT UNSIGNED NOT NULL,
    description         TEXT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    created_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by          BIGINT UNSIGNED NULL,
    updated_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                  ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by          BIGINT UNSIGNED NULL,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at          DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_rooms_building_number UNIQUE (building_id, room_number),
    CONSTRAINT fk_rooms_building FOREIGN KEY (building_id) REFERENCES buildings(id),
    CONSTRAINT fk_rooms_floor_building FOREIGN KEY (floor_id, building_id)
        REFERENCES floors(id, building_id),
    CONSTRAINT fk_rooms_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_rooms_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_rooms_area CHECK (area_m2 > 0),
    CONSTRAINT chk_rooms_rent CHECK (default_rent >= 0),
    CONSTRAINT chk_rooms_deposit CHECK (default_deposit >= 0),
    CONSTRAINT chk_rooms_capacity CHECK (max_occupants > 0),
    CONSTRAINT chk_rooms_status CHECK (
        status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'INACTIVE')
    )
) ENGINE=InnoDB;

CREATE INDEX idx_rooms_floor_status ON rooms(floor_id, status, is_deleted);
CREATE INDEX idx_rooms_status ON rooms(status, is_deleted);

-- ============================================================
-- 3. Tenant and occupant profiles
-- Phone/email are stored in users to guarantee account-level uniqueness.
-- ============================================================

CREATE TABLE tenant_profiles (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                     BIGINT UNSIGNED NOT NULL,
    full_name                   VARCHAR(150) NOT NULL,
    date_of_birth               DATE NOT NULL,
    identity_type               VARCHAR(20) NOT NULL DEFAULT 'CCCD',
    identity_number             VARCHAR(30) NOT NULL,
    identity_issued_date        DATE NULL,
    identity_issued_place       VARCHAR(255) NULL,
    permanent_address           VARCHAR(500) NOT NULL,
    emergency_contact_name      VARCHAR(150) NULL,
    emergency_contact_phone     VARCHAR(20) NULL,
    status                      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by                  BIGINT UNSIGNED NULL,
    updated_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                          ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by                  BIGINT UNSIGNED NULL,
    is_deleted                  BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at                  DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_tenant_profiles_user UNIQUE (user_id),
    CONSTRAINT uq_tenant_profiles_identity UNIQUE (identity_number),
    CONSTRAINT fk_tenant_profiles_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_tenant_profiles_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_tenant_profiles_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_tenant_profiles_identity_type CHECK (
        identity_type IN ('CCCD', 'PASSPORT', 'OTHER')
    ),
    CONSTRAINT chk_tenant_profiles_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB;

CREATE TABLE occupants (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name               VARCHAR(150) NOT NULL,
    date_of_birth           DATE NULL,
    phone                   VARCHAR(20) NULL,
    identity_type           VARCHAR(20) NULL,
    identity_number         VARCHAR(30) NULL,
    permanent_address       VARCHAR(500) NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by              BIGINT UNSIGNED NULL,
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_occupants_identity UNIQUE (identity_number),
    CONSTRAINT fk_occupants_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_occupants_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_occupants_identity_type CHECK (
        identity_type IS NULL OR identity_type IN ('CCCD', 'PASSPORT', 'OTHER')
    ),
    CONSTRAINT chk_occupants_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB;

-- ============================================================
-- 4. Rental contracts and residents
-- Generated active_room_id creates a partial-unique behavior in MySQL:
-- only one non-deleted ACTIVE contract is allowed for each room.
-- ============================================================

CREATE TABLE rental_contracts (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    contract_code           VARCHAR(50) NOT NULL,
    room_id                 BIGINT UNSIGNED NOT NULL,
    primary_tenant_id       BIGINT UNSIGNED NOT NULL,
    renewed_from_contract_id BIGINT UNSIGNED NULL,
    start_date              DATE NOT NULL,
    end_date                DATE NOT NULL,
    applied_rent            DECIMAL(18,2) NOT NULL,
    deposit_amount          DECIMAL(18,2) NOT NULL DEFAULT 0,
    monthly_due_day         TINYINT UNSIGNED NOT NULL DEFAULT 5,
    terms                   TEXT NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    activated_at            DATETIME(6) NULL,
    ended_at                DATETIME(6) NULL,
    termination_reason      VARCHAR(500) NULL,
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by              BIGINT UNSIGNED NULL,
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              DATETIME(6) NULL,
    active_room_id          BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status = 'ACTIVE' AND is_deleted = FALSE THEN room_id
            ELSE NULL
        END
    ) STORED,
    PRIMARY KEY (id),
    CONSTRAINT uq_rental_contracts_code UNIQUE (contract_code),
    CONSTRAINT uq_rental_contracts_active_room UNIQUE (active_room_id),
    CONSTRAINT fk_rental_contracts_room FOREIGN KEY (room_id) REFERENCES rooms(id),
    CONSTRAINT fk_rental_contracts_tenant FOREIGN KEY (primary_tenant_id) REFERENCES tenant_profiles(id),
    CONSTRAINT fk_rental_contracts_previous FOREIGN KEY (renewed_from_contract_id)
        REFERENCES rental_contracts(id) ON DELETE SET NULL,
    CONSTRAINT fk_rental_contracts_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_rental_contracts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_rental_contracts_dates CHECK (end_date > start_date),
    CONSTRAINT chk_rental_contracts_rent CHECK (applied_rent > 0),
    CONSTRAINT chk_rental_contracts_deposit CHECK (deposit_amount >= 0),
    CONSTRAINT chk_rental_contracts_due_day CHECK (monthly_due_day BETWEEN 1 AND 31),
    CONSTRAINT chk_rental_contracts_status CHECK (
        status IN ('DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'CANCELLED')
    )
) ENGINE=InnoDB;

CREATE INDEX idx_contracts_room_status ON rental_contracts(room_id, status, is_deleted);
CREATE INDEX idx_contracts_tenant_status ON rental_contracts(primary_tenant_id, status, is_deleted);
CREATE INDEX idx_contracts_end_date_status ON rental_contracts(end_date, status, is_deleted);

CREATE TABLE contract_occupants (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    contract_id             BIGINT UNSIGNED NOT NULL,
    occupant_id             BIGINT UNSIGNED NOT NULL,
    relationship_to_primary VARCHAR(100) NOT NULL,
    move_in_date            DATE NOT NULL,
    move_out_date           DATE NULL,
    notes                   VARCHAR(500) NULL,
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by              BIGINT UNSIGNED NULL,
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_contract_occupants UNIQUE (contract_id, occupant_id),
    CONSTRAINT fk_contract_occupants_contract FOREIGN KEY (contract_id) REFERENCES rental_contracts(id),
    CONSTRAINT fk_contract_occupants_occupant FOREIGN KEY (occupant_id) REFERENCES occupants(id),
    CONSTRAINT fk_contract_occupants_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_contract_occupants_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_contract_occupants_dates CHECK (
        move_out_date IS NULL OR move_out_date >= move_in_date
    )
) ENGINE=InnoDB;

CREATE INDEX idx_contract_occupants_current
    ON contract_occupants(contract_id, move_out_date, is_deleted);

-- ============================================================
-- 5. Services and price history
-- Price is separated from services so a new price never changes old bills.
-- ============================================================

CREATE TABLE services (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(150) NOT NULL,
    unit                VARCHAR(50) NOT NULL,
    charge_type         VARCHAR(30) NOT NULL,
    description         VARCHAR(500) NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by          BIGINT UNSIGNED NULL,
    updated_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                  ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by          BIGINT UNSIGNED NULL,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at          DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_services_code UNIQUE (code),
    CONSTRAINT fk_services_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_services_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_services_charge_type CHECK (
        charge_type IN ('METERED', 'FIXED_PER_ROOM', 'FIXED_PER_PERSON')
    ),
    CONSTRAINT chk_services_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
) ENGINE=InnoDB;

CREATE TABLE service_prices (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_id          BIGINT UNSIGNED NOT NULL,
    unit_price          DECIMAL(18,2) NOT NULL,
    effective_from      DATE NOT NULL,
    effective_to        DATE NULL,
    notes               VARCHAR(500) NULL,
    created_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by          BIGINT UNSIGNED NULL,
    updated_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                  ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by          BIGINT UNSIGNED NULL,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at          DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_service_prices_start UNIQUE (service_id, effective_from),
    CONSTRAINT fk_service_prices_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT fk_service_prices_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_service_prices_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_service_prices_value CHECK (unit_price >= 0),
    CONSTRAINT chk_service_prices_dates CHECK (
        effective_to IS NULL OR effective_to >= effective_from
    )
) ENGINE=InnoDB;

CREATE INDEX idx_service_prices_lookup
    ON service_prices(service_id, effective_from, effective_to, is_deleted);

CREATE TABLE contract_services (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    contract_id                 BIGINT UNSIGNED NOT NULL,
    service_id                  BIGINT UNSIGNED NOT NULL,
    start_date                  DATE NOT NULL,
    end_date                    DATE NULL,
    status                      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    notes                       VARCHAR(500) NULL,
    created_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by                  BIGINT UNSIGNED NULL,
    updated_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                          ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by                  BIGINT UNSIGNED NULL,
    is_deleted                  BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at                  DATETIME(6) NULL,
    active_contract_id          BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status = 'ACTIVE' AND is_deleted = FALSE THEN contract_id
            ELSE NULL
        END
    ) STORED,
    active_service_id           BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status = 'ACTIVE' AND is_deleted = FALSE THEN service_id
            ELSE NULL
        END
    ) STORED,
    PRIMARY KEY (id),
    CONSTRAINT uq_contract_services_active UNIQUE (active_contract_id, active_service_id),
    CONSTRAINT fk_contract_services_contract FOREIGN KEY (contract_id) REFERENCES rental_contracts(id),
    CONSTRAINT fk_contract_services_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT fk_contract_services_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_contract_services_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_contract_services_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT chk_contract_services_dates CHECK (
        end_date IS NULL OR end_date >= start_date
    )
) ENGINE=InnoDB;

CREATE INDEX idx_contract_services_contract
    ON contract_services(contract_id, status, is_deleted);

-- ============================================================
-- 6. Meter readings
-- ============================================================

CREATE TABLE meter_readings (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    room_id                 BIGINT UNSIGNED NOT NULL,
    service_id              BIGINT UNSIGNED NOT NULL,
    billing_month           TINYINT UNSIGNED NOT NULL,
    billing_year            SMALLINT UNSIGNED NOT NULL,
    previous_reading        DECIMAL(14,3) NOT NULL,
    current_reading         DECIMAL(14,3) NOT NULL,
    consumption             DECIMAL(14,3) GENERATED ALWAYS AS (
        current_reading - previous_reading
    ) STORED,
    reading_date            DATE NOT NULL,
    recorded_by             BIGINT UNSIGNED NOT NULL,
    notes                   VARCHAR(500) NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_meter_readings_period UNIQUE (
        room_id, service_id, billing_year, billing_month
    ),
    CONSTRAINT fk_meter_readings_room FOREIGN KEY (room_id) REFERENCES rooms(id),
    CONSTRAINT fk_meter_readings_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT fk_meter_readings_recorded_by FOREIGN KEY (recorded_by) REFERENCES users(id),
    CONSTRAINT fk_meter_readings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_meter_readings_month CHECK (billing_month BETWEEN 1 AND 12),
    CONSTRAINT chk_meter_readings_year CHECK (billing_year BETWEEN 2000 AND 2100),
    CONSTRAINT chk_meter_readings_values CHECK (
        previous_reading >= 0 AND current_reading >= previous_reading
    ),
    CONSTRAINT chk_meter_readings_status CHECK (
        status IN ('DRAFT', 'LOCKED', 'CANCELLED')
    )
) ENGINE=InnoDB;

CREATE INDEX idx_meter_readings_period
    ON meter_readings(billing_year, billing_month, room_id, status);

-- ============================================================
-- 7. Invoices and invoice items
-- A cancelled invoice frees the period so a replacement can be created.
-- ============================================================

CREATE TABLE invoices (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    invoice_number              VARCHAR(50) NOT NULL,
    contract_id                 BIGINT UNSIGNED NOT NULL,
    room_id                     BIGINT UNSIGNED NOT NULL,
    tenant_profile_id           BIGINT UNSIGNED NOT NULL,
    billing_month               TINYINT UNSIGNED NOT NULL,
    billing_year                SMALLINT UNSIGNED NOT NULL,
    issue_date                  DATE NULL,
    due_date                    DATE NOT NULL,
    status                      VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    total_amount                DECIMAL(18,2) NOT NULL DEFAULT 0,
    paid_amount                 DECIMAL(18,2) NOT NULL DEFAULT 0,
    remaining_amount            DECIMAL(18,2) GENERATED ALWAYS AS (
        total_amount - paid_amount
    ) STORED,
    notes                       VARCHAR(1000) NULL,
    issued_at                   DATETIME(6) NULL,
    cancelled_at                DATETIME(6) NULL,
    cancellation_reason         VARCHAR(500) NULL,
    created_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by                  BIGINT UNSIGNED NULL,
    updated_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                          ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by                  BIGINT UNSIGNED NULL,
    is_deleted                  BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at                  DATETIME(6) NULL,
    current_contract_id         BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status <> 'CANCELLED' AND is_deleted = FALSE THEN contract_id
            ELSE NULL
        END
    ) STORED,
    current_billing_year        SMALLINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status <> 'CANCELLED' AND is_deleted = FALSE THEN billing_year
            ELSE NULL
        END
    ) STORED,
    current_billing_month       TINYINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status <> 'CANCELLED' AND is_deleted = FALSE THEN billing_month
            ELSE NULL
        END
    ) STORED,
    PRIMARY KEY (id),
    CONSTRAINT uq_invoices_number UNIQUE (invoice_number),
    CONSTRAINT uq_invoices_current_period UNIQUE (
        current_contract_id, current_billing_year, current_billing_month
    ),
    CONSTRAINT fk_invoices_contract FOREIGN KEY (contract_id) REFERENCES rental_contracts(id),
    CONSTRAINT fk_invoices_room FOREIGN KEY (room_id) REFERENCES rooms(id),
    CONSTRAINT fk_invoices_tenant FOREIGN KEY (tenant_profile_id) REFERENCES tenant_profiles(id),
    CONSTRAINT fk_invoices_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_invoices_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_invoices_month CHECK (billing_month BETWEEN 1 AND 12),
    CONSTRAINT chk_invoices_year CHECK (billing_year BETWEEN 2000 AND 2100),
    CONSTRAINT chk_invoices_amounts CHECK (
        total_amount >= 0 AND paid_amount >= 0 AND paid_amount <= total_amount
    ),
    CONSTRAINT chk_invoices_status CHECK (
        status IN (
            'DRAFT', 'ISSUED', 'PARTIALLY_PAID',
            'PAID', 'OVERDUE', 'CANCELLED'
        )
    )
) ENGINE=InnoDB;

CREATE INDEX idx_invoices_tenant_period
    ON invoices(tenant_profile_id, billing_year, billing_month, status);
CREATE INDEX idx_invoices_status_due_date
    ON invoices(status, due_date, is_deleted);
CREATE INDEX idx_invoices_contract_period
    ON invoices(contract_id, billing_year, billing_month);

CREATE TABLE invoice_items (
    id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    invoice_id                  BIGINT UNSIGNED NOT NULL,
    item_type                   VARCHAR(30) NOT NULL,
    service_id                  BIGINT UNSIGNED NULL,
    contract_service_id         BIGINT UNSIGNED NULL,
    meter_reading_id            BIGINT UNSIGNED NULL,
    description                 VARCHAR(255) NOT NULL,
    quantity                    DECIMAL(14,3) NOT NULL DEFAULT 1,
    unit                        VARCHAR(50) NOT NULL,
    unit_price                  DECIMAL(18,2) NOT NULL,
    amount                      DECIMAL(18,2) NOT NULL,
    display_order               INT NOT NULL DEFAULT 0,
    created_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by                  BIGINT UNSIGNED NULL,
    updated_at                  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                          ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by                  BIGINT UNSIGNED NULL,
    is_deleted                  BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at                  DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_invoice_items_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT fk_invoice_items_contract_service FOREIGN KEY (contract_service_id)
        REFERENCES contract_services(id),
    CONSTRAINT fk_invoice_items_meter_reading FOREIGN KEY (meter_reading_id)
        REFERENCES meter_readings(id),
    CONSTRAINT fk_invoice_items_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_invoice_items_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_invoice_items_type CHECK (
        item_type IN ('RENT', 'METERED_SERVICE', 'FIXED_SERVICE', 'ADJUSTMENT')
    ),
    CONSTRAINT chk_invoice_items_quantity CHECK (quantity >= 0),
    CONSTRAINT chk_invoice_items_amount CHECK (
        item_type = 'ADJUSTMENT' OR amount >= 0
    )
) ENGINE=InnoDB;

CREATE INDEX idx_invoice_items_invoice
    ON invoice_items(invoice_id, display_order, is_deleted);
CREATE INDEX idx_invoice_items_meter
    ON invoice_items(meter_reading_id);

-- ============================================================
-- 8. Payments and debt
-- Payments are never deleted. Incorrect transactions are cancelled.
-- ============================================================

CREATE TABLE payments (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    payment_number          VARCHAR(50) NOT NULL,
    invoice_id              BIGINT UNSIGNED NOT NULL,
    amount                  DECIMAL(18,2) NOT NULL,
    payment_date            DATETIME(6) NOT NULL,
    method                  VARCHAR(30) NOT NULL,
    transaction_reference   VARCHAR(100) NULL,
    notes                   VARCHAR(500) NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    confirmed_by            BIGINT UNSIGNED NOT NULL,
    cancelled_at            DATETIME(6) NULL,
    cancelled_by            BIGINT UNSIGNED NULL,
    cancellation_reason     VARCHAR(500) NULL,
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by              BIGINT UNSIGNED NULL,
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_payments_number UNIQUE (payment_number),
    CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_payments_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES users(id),
    CONSTRAINT fk_payments_cancelled_by FOREIGN KEY (cancelled_by) REFERENCES users(id),
    CONSTRAINT fk_payments_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT chk_payments_method CHECK (
        method IN ('CASH', 'BANK_TRANSFER', 'OTHER')
    ),
    CONSTRAINT chk_payments_status CHECK (
        status IN ('CONFIRMED', 'CANCELLED')
    ),
    CONSTRAINT chk_payments_cancel_fields CHECK (
        (status = 'CONFIRMED' AND cancelled_at IS NULL AND cancelled_by IS NULL AND cancellation_reason IS NULL)
        OR
        (status = 'CANCELLED' AND cancelled_at IS NOT NULL
            AND cancelled_by IS NOT NULL
            AND cancellation_reason IS NOT NULL)
    )
) ENGINE=InnoDB;

CREATE INDEX idx_payments_invoice_status
    ON payments(invoice_id, status, payment_date);
CREATE INDEX idx_payments_date
    ON payments(payment_date);

-- ============================================================
-- 9. Maintenance requests
-- ============================================================

CREATE TABLE maintenance_requests (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_number          VARCHAR(50) NOT NULL,
    contract_id             BIGINT UNSIGNED NOT NULL,
    room_id                 BIGINT UNSIGNED NOT NULL,
    requester_user_id       BIGINT UNSIGNED NOT NULL,
    title                   VARCHAR(200) NOT NULL,
    description             TEXT NOT NULL,
    priority                VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status                  VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    resolution_summary      TEXT NULL,
    rejected_reason         VARCHAR(500) NULL,
    submitted_at            DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    received_at             DATETIME(6) NULL,
    resolved_at             DATETIME(6) NULL,
    cancelled_at            DATETIME(6) NULL,
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by              BIGINT UNSIGNED NULL,
    updated_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                      ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by              BIGINT UNSIGNED NULL,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_maintenance_requests_number UNIQUE (request_number),
    CONSTRAINT fk_maintenance_requests_contract FOREIGN KEY (contract_id) REFERENCES rental_contracts(id),
    CONSTRAINT fk_maintenance_requests_room FOREIGN KEY (room_id) REFERENCES rooms(id),
    CONSTRAINT fk_maintenance_requests_requester FOREIGN KEY (requester_user_id) REFERENCES users(id),
    CONSTRAINT fk_maintenance_requests_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_maintenance_requests_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_maintenance_requests_priority CHECK (
        priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')
    ),
    CONSTRAINT chk_maintenance_requests_status CHECK (
        status IN ('OPEN', 'RECEIVED', 'IN_PROGRESS', 'RESOLVED', 'CANCELLED', 'REJECTED')
    )
) ENGINE=InnoDB;

CREATE INDEX idx_maintenance_requests_status_priority
    ON maintenance_requests(status, priority, submitted_at, is_deleted);
CREATE INDEX idx_maintenance_requests_room
    ON maintenance_requests(room_id, status, is_deleted);
CREATE INDEX idx_maintenance_requests_requester
    ON maintenance_requests(requester_user_id, submitted_at);

CREATE TABLE maintenance_updates (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_id          BIGINT UNSIGNED NOT NULL,
    old_status          VARCHAR(30) NULL,
    new_status          VARCHAR(30) NOT NULL,
    content             TEXT NOT NULL,
    created_at          DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by          BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_maintenance_updates_request FOREIGN KEY (request_id)
        REFERENCES maintenance_requests(id),
    CONSTRAINT fk_maintenance_updates_created_by FOREIGN KEY (created_by)
        REFERENCES users(id),
    CONSTRAINT chk_maintenance_updates_old_status CHECK (
        old_status IS NULL OR old_status IN (
            'OPEN', 'RECEIVED', 'IN_PROGRESS', 'RESOLVED', 'CANCELLED', 'REJECTED'
        )
    ),
    CONSTRAINT chk_maintenance_updates_new_status CHECK (
        new_status IN (
            'OPEN', 'RECEIVED', 'IN_PROGRESS', 'RESOLVED', 'CANCELLED', 'REJECTED'
        )
    )
) ENGINE=InnoDB;

CREATE INDEX idx_maintenance_updates_request
    ON maintenance_updates(request_id, created_at);

-- ============================================================
-- 10. In-app notifications
-- ============================================================

CREATE TABLE notifications (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id                 BIGINT UNSIGNED NOT NULL,
    notification_type       VARCHAR(50) NOT NULL,
    title                   VARCHAR(200) NOT NULL,
    message                 VARCHAR(1000) NOT NULL,
    related_entity_type     VARCHAR(30) NULL,
    related_entity_id       BIGINT UNSIGNED NULL,
    is_read                 BOOLEAN NOT NULL DEFAULT FALSE,
    read_at                 DATETIME(6) NULL,
    created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT chk_notifications_type CHECK (
        notification_type IN (
            'INVOICE_ISSUED',
            'INVOICE_DUE_SOON',
            'INVOICE_OVERDUE',
            'PAYMENT_CONFIRMED',
            'CONTRACT_EXPIRING',
            'MAINTENANCE_STATUS_CHANGED',
            'GENERAL'
        )
    ),
    CONSTRAINT chk_notifications_entity_type CHECK (
        related_entity_type IS NULL OR related_entity_type IN (
            'CONTRACT', 'INVOICE', 'PAYMENT', 'MAINTENANCE_REQUEST'
        )
    ),
    CONSTRAINT chk_notifications_read CHECK (
        (is_read = FALSE AND read_at IS NULL)
        OR (is_read = TRUE AND read_at IS NOT NULL)
    )
) ENGINE=InnoDB;

CREATE INDEX idx_notifications_user_read
    ON notifications(user_id, is_read, created_at);

-- ============================================================
-- Stored procedures
-- ============================================================

DELIMITER $$

CREATE PROCEDURE sp_recalculate_invoice_payment(IN p_invoice_id BIGINT UNSIGNED)
BEGIN
    DECLARE v_paid DECIMAL(18,2) DEFAULT 0;

    SELECT COALESCE(SUM(amount), 0)
      INTO v_paid
      FROM payments
     WHERE invoice_id = p_invoice_id
       AND status = 'CONFIRMED';

    UPDATE invoices
       SET paid_amount = v_paid,
           status = CASE
               WHEN status = 'CANCELLED' THEN 'CANCELLED'
               WHEN v_paid >= total_amount THEN 'PAID'
               WHEN due_date < CURRENT_DATE THEN 'OVERDUE'
               WHEN v_paid > 0 THEN 'PARTIALLY_PAID'
               WHEN issued_at IS NOT NULL THEN 'ISSUED'
               ELSE 'DRAFT'
           END
     WHERE id = p_invoice_id;
END$$

CREATE PROCEDURE sp_mark_overdue_invoices()
BEGIN
    UPDATE invoices
       SET status = 'OVERDUE'
     WHERE status IN ('ISSUED', 'PARTIALLY_PAID')
       AND due_date < CURRENT_DATE
       AND remaining_amount > 0
       AND is_deleted = FALSE;
END$$

-- ============================================================
-- Triggers: account/profile rules
-- ============================================================

CREATE TRIGGER trg_tenant_profiles_role_bi
BEFORE INSERT ON tenant_profiles
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM users u
          JOIN roles r ON r.id = u.role_id
         WHERE u.id = NEW.user_id
           AND r.code = 'TENANT'
           AND u.is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tenant profile must be linked to an active TENANT account';
    END IF;
END$$

CREATE TRIGGER trg_tenant_profiles_role_bu
BEFORE UPDATE ON tenant_profiles
FOR EACH ROW
BEGIN
    IF NEW.user_id <> OLD.user_id AND NOT EXISTS (
        SELECT 1
          FROM users u
          JOIN roles r ON r.id = u.role_id
         WHERE u.id = NEW.user_id
           AND r.code = 'TENANT'
           AND u.is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tenant profile must be linked to an active TENANT account';
    END IF;
END$$

-- ============================================================
-- Triggers: contract and room rules
-- ============================================================

CREATE TRIGGER trg_contracts_validate_bi
BEFORE INSERT ON rental_contracts
FOR EACH ROW
BEGIN
    DECLARE v_room_status VARCHAR(20);
    DECLARE v_capacity INT DEFAULT 0;
    DECLARE v_occupants INT DEFAULT 0;

    IF NEW.end_date <= NEW.start_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Contract end date must be after start date';
    END IF;

    IF NEW.applied_rent <= 0 OR NEW.deposit_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Contract rent/deposit is invalid';
    END IF;

    IF NEW.status = 'ACTIVE' THEN
        SELECT status, max_occupants
          INTO v_room_status, v_capacity
          FROM rooms
         WHERE id = NEW.room_id
           AND is_deleted = FALSE;

        IF v_room_status <> 'AVAILABLE' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Only an AVAILABLE room can activate a contract';
        END IF;

        SELECT COUNT(*)
          INTO v_occupants
          FROM contract_occupants
         WHERE contract_id = NEW.id
           AND move_out_date IS NULL
           AND is_deleted = FALSE;

        IF 1 + v_occupants > v_capacity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Room capacity would be exceeded';
        END IF;

        SET NEW.activated_at = COALESCE(NEW.activated_at, CURRENT_TIMESTAMP(6));
    END IF;
END$$

CREATE TRIGGER trg_contracts_validate_bu
BEFORE UPDATE ON rental_contracts
FOR EACH ROW
BEGIN
    DECLARE v_room_status VARCHAR(20);
    DECLARE v_capacity INT DEFAULT 0;
    DECLARE v_occupants INT DEFAULT 0;

    IF NEW.end_date <= NEW.start_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Contract end date must be after start date';
    END IF;

    IF NEW.applied_rent <= 0 OR NEW.deposit_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Contract rent/deposit is invalid';
    END IF;

    IF OLD.status = 'ACTIVE' AND NEW.room_id <> OLD.room_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An ACTIVE contract cannot be moved to another room';
    END IF;

    IF OLD.status <> 'ACTIVE' AND NEW.status = 'ACTIVE' THEN
        SELECT status, max_occupants
          INTO v_room_status, v_capacity
          FROM rooms
         WHERE id = NEW.room_id
           AND is_deleted = FALSE;

        IF v_room_status <> 'AVAILABLE' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Only an AVAILABLE room can activate a contract';
        END IF;

        SELECT COUNT(*)
          INTO v_occupants
          FROM contract_occupants
         WHERE contract_id = NEW.id
           AND move_out_date IS NULL
           AND is_deleted = FALSE;

        IF 1 + v_occupants > v_capacity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Room capacity would be exceeded';
        END IF;

        SET NEW.activated_at = COALESCE(NEW.activated_at, CURRENT_TIMESTAMP(6));
    END IF;

    IF OLD.status = 'ACTIVE'
       AND NEW.status IN ('EXPIRED', 'TERMINATED', 'CANCELLED') THEN
        SET NEW.ended_at = COALESCE(NEW.ended_at, CURRENT_TIMESTAMP(6));
    END IF;
END$$

CREATE TRIGGER trg_contracts_room_status_ai
AFTER INSERT ON rental_contracts
FOR EACH ROW
BEGIN
    IF NEW.status = 'ACTIVE' AND NEW.is_deleted = FALSE THEN
        UPDATE rooms
           SET status = 'OCCUPIED',
               updated_at = CURRENT_TIMESTAMP(6),
               updated_by = NEW.created_by
         WHERE id = NEW.room_id;
    END IF;
END$$

CREATE TRIGGER trg_contracts_room_status_au
AFTER UPDATE ON rental_contracts
FOR EACH ROW
BEGIN
    IF OLD.status <> 'ACTIVE'
       AND NEW.status = 'ACTIVE'
       AND NEW.is_deleted = FALSE THEN
        UPDATE rooms
           SET status = 'OCCUPIED',
               updated_at = CURRENT_TIMESTAMP(6),
               updated_by = NEW.updated_by
         WHERE id = NEW.room_id;
    END IF;

    IF OLD.status = 'ACTIVE'
       AND (NEW.status <> 'ACTIVE' OR NEW.is_deleted = TRUE) THEN
        UPDATE rooms r
           SET r.status = 'AVAILABLE',
               r.updated_at = CURRENT_TIMESTAMP(6),
               r.updated_by = NEW.updated_by
         WHERE r.id = OLD.room_id
           AND r.status = 'OCCUPIED'
           AND NOT EXISTS (
               SELECT 1
                 FROM rental_contracts c
                WHERE c.room_id = OLD.room_id
                  AND c.status = 'ACTIVE'
                  AND c.is_deleted = FALSE
           );
    END IF;
END$$

CREATE TRIGGER trg_rooms_status_bu
BEFORE UPDATE ON rooms
FOR EACH ROW
BEGIN
    DECLARE v_active_contracts INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_active_contracts
      FROM rental_contracts
     WHERE room_id = NEW.id
       AND status = 'ACTIVE'
       AND is_deleted = FALSE;

    IF v_active_contracts > 0 AND NEW.status <> 'OCCUPIED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A room with an ACTIVE contract must remain OCCUPIED';
    END IF;

    IF v_active_contracts = 0 AND NEW.status = 'OCCUPIED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A room cannot be OCCUPIED without an ACTIVE contract';
    END IF;
END$$

CREATE TRIGGER trg_contract_occupants_validate_bi
BEFORE INSERT ON contract_occupants
FOR EACH ROW
BEGIN
    DECLARE v_start DATE;
    DECLARE v_end DATE;
    DECLARE v_capacity INT;
    DECLARE v_current_count INT;

    SELECT c.start_date, c.end_date, r.max_occupants
      INTO v_start, v_end, v_capacity
      FROM rental_contracts c
      JOIN rooms r ON r.id = c.room_id
     WHERE c.id = NEW.contract_id;

    IF NEW.move_in_date < v_start OR NEW.move_in_date > v_end THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Occupant move-in date must be within contract dates';
    END IF;

    IF NEW.move_out_date IS NOT NULL
       AND (NEW.move_out_date < NEW.move_in_date OR NEW.move_out_date > v_end) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Occupant move-out date is invalid';
    END IF;

    IF NEW.move_out_date IS NULL AND NEW.is_deleted = FALSE THEN
        SELECT COUNT(*)
          INTO v_current_count
          FROM contract_occupants
         WHERE contract_id = NEW.contract_id
           AND move_out_date IS NULL
           AND is_deleted = FALSE;

        IF 1 + v_current_count + 1 > v_capacity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Room capacity would be exceeded';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_contract_occupants_validate_bu
BEFORE UPDATE ON contract_occupants
FOR EACH ROW
BEGIN
    DECLARE v_start DATE;
    DECLARE v_end DATE;
    DECLARE v_capacity INT;
    DECLARE v_current_count INT;

    SELECT c.start_date, c.end_date, r.max_occupants
      INTO v_start, v_end, v_capacity
      FROM rental_contracts c
      JOIN rooms r ON r.id = c.room_id
     WHERE c.id = NEW.contract_id;

    IF NEW.move_in_date < v_start OR NEW.move_in_date > v_end THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Occupant move-in date must be within contract dates';
    END IF;

    IF NEW.move_out_date IS NOT NULL
       AND (NEW.move_out_date < NEW.move_in_date OR NEW.move_out_date > v_end) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Occupant move-out date is invalid';
    END IF;

    IF NEW.move_out_date IS NULL AND NEW.is_deleted = FALSE THEN
        SELECT COUNT(*)
          INTO v_current_count
          FROM contract_occupants
         WHERE contract_id = NEW.contract_id
           AND id <> OLD.id
           AND move_out_date IS NULL
           AND is_deleted = FALSE;

        IF 1 + v_current_count + 1 > v_capacity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Room capacity would be exceeded';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_service_prices_validate_bi
BEFORE INSERT ON service_prices
FOR EACH ROW
BEGIN
    IF NEW.is_deleted = FALSE AND EXISTS (
        SELECT 1
          FROM service_prices sp
         WHERE sp.service_id = NEW.service_id
           AND sp.is_deleted = FALSE
           AND NEW.effective_from <= COALESCE(sp.effective_to, '9999-12-31')
           AND COALESCE(NEW.effective_to, '9999-12-31') >= sp.effective_from
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service price periods cannot overlap';
    END IF;
END$$

CREATE TRIGGER trg_service_prices_validate_bu
BEFORE UPDATE ON service_prices
FOR EACH ROW
BEGIN
    IF NEW.is_deleted = FALSE AND EXISTS (
        SELECT 1
          FROM service_prices sp
         WHERE sp.service_id = NEW.service_id
           AND sp.id <> OLD.id
           AND sp.is_deleted = FALSE
           AND NEW.effective_from <= COALESCE(sp.effective_to, '9999-12-31')
           AND COALESCE(NEW.effective_to, '9999-12-31') >= sp.effective_from
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service price periods cannot overlap';
    END IF;
END$$

CREATE TRIGGER trg_contract_services_validate_bi
BEFORE INSERT ON contract_services
FOR EACH ROW
BEGIN
    DECLARE v_contract_start DATE;
    DECLARE v_contract_end DATE;

    SELECT start_date, end_date
      INTO v_contract_start, v_contract_end
      FROM rental_contracts
     WHERE id = NEW.contract_id;

    IF NEW.start_date < v_contract_start OR NEW.start_date > v_contract_end THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service start date must be within contract dates';
    END IF;

    IF NEW.end_date IS NOT NULL
       AND (NEW.end_date < NEW.start_date OR NEW.end_date > v_contract_end) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service end date is invalid';
    END IF;
END$$

CREATE TRIGGER trg_contract_services_validate_bu
BEFORE UPDATE ON contract_services
FOR EACH ROW
BEGIN
    DECLARE v_contract_start DATE;
    DECLARE v_contract_end DATE;

    SELECT start_date, end_date
      INTO v_contract_start, v_contract_end
      FROM rental_contracts
     WHERE id = NEW.contract_id;

    IF NEW.start_date < v_contract_start OR NEW.start_date > v_contract_end THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service start date must be within contract dates';
    END IF;

    IF NEW.end_date IS NOT NULL
       AND (NEW.end_date < NEW.start_date OR NEW.end_date > v_contract_end) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service end date is invalid';
    END IF;
END$$

-- ============================================================
-- Triggers: meter readings
-- ============================================================

CREATE TRIGGER trg_meter_readings_validate_bi
BEFORE INSERT ON meter_readings
FOR EACH ROW
BEGIN
    IF NEW.current_reading < NEW.previous_reading THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Current meter reading cannot be lower than previous reading';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM services
         WHERE id = NEW.service_id
           AND charge_type = 'METERED'
           AND status = 'ACTIVE'
           AND is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Meter readings are allowed only for active METERED services';
    END IF;
END$$

CREATE TRIGGER trg_meter_readings_validate_bu
BEFORE UPDATE ON meter_readings
FOR EACH ROW
BEGIN
    IF OLD.status = 'LOCKED'
       AND (
           NEW.previous_reading <> OLD.previous_reading
           OR NEW.current_reading <> OLD.current_reading
           OR NEW.room_id <> OLD.room_id
           OR NEW.service_id <> OLD.service_id
           OR NEW.billing_month <> OLD.billing_month
           OR NEW.billing_year <> OLD.billing_year
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A LOCKED meter reading cannot be edited directly';
    END IF;

    IF NEW.current_reading < NEW.previous_reading THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Current meter reading cannot be lower than previous reading';
    END IF;
END$$

-- ============================================================
-- Triggers: invoice items and invoice lifecycle
-- ============================================================

CREATE TRIGGER trg_invoices_validate_bi
BEFORE INSERT ON invoices
FOR EACH ROW
BEGIN
    IF NEW.status <> 'DRAFT' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A new invoice must start as DRAFT';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM rental_contracts c
         WHERE c.id = NEW.contract_id
           AND c.room_id = NEW.room_id
           AND c.primary_tenant_id = NEW.tenant_profile_id
           AND c.status = 'ACTIVE'
           AND c.is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invoice must match an ACTIVE contract, room and primary tenant';
    END IF;
END$$

CREATE TRIGGER trg_invoice_items_validate_bi
BEFORE INSERT ON invoice_items
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM invoices
         WHERE id = NEW.invoice_id
           AND status = 'DRAFT'
           AND is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invoice items can only be added to a DRAFT invoice';
    END IF;
END$$

CREATE TRIGGER trg_invoice_items_validate_bu
BEFORE UPDATE ON invoice_items
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM invoices
         WHERE id = OLD.invoice_id
           AND status = 'DRAFT'
           AND is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invoice items can only be changed on a DRAFT invoice';
    END IF;

    IF NEW.invoice_id <> OLD.invoice_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An invoice item cannot be moved to another invoice';
    END IF;
END$$

CREATE TRIGGER trg_invoice_items_validate_bd
BEFORE DELETE ON invoice_items
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM invoices
         WHERE id = OLD.invoice_id
           AND status = 'DRAFT'
           AND is_deleted = FALSE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invoice items can only be deleted from a DRAFT invoice';
    END IF;
END$$

CREATE TRIGGER trg_invoice_items_total_ai
AFTER INSERT ON invoice_items
FOR EACH ROW
BEGIN
    UPDATE invoices
       SET total_amount = (
           SELECT COALESCE(SUM(amount), 0)
             FROM invoice_items
            WHERE invoice_id = NEW.invoice_id
              AND is_deleted = FALSE
       )
     WHERE id = NEW.invoice_id;
END$$

CREATE TRIGGER trg_invoice_items_total_au
AFTER UPDATE ON invoice_items
FOR EACH ROW
BEGIN
    UPDATE invoices
       SET total_amount = (
           SELECT COALESCE(SUM(amount), 0)
             FROM invoice_items
            WHERE invoice_id = NEW.invoice_id
              AND is_deleted = FALSE
       )
     WHERE id = NEW.invoice_id;
END$$

CREATE TRIGGER trg_invoice_items_total_ad
AFTER DELETE ON invoice_items
FOR EACH ROW
BEGIN
    UPDATE invoices
       SET total_amount = (
           SELECT COALESCE(SUM(amount), 0)
             FROM invoice_items
            WHERE invoice_id = OLD.invoice_id
              AND is_deleted = FALSE
       )
     WHERE id = OLD.invoice_id;
END$$

CREATE TRIGGER trg_invoices_validate_bu
BEFORE UPDATE ON invoices
FOR EACH ROW
BEGIN
    IF OLD.status = 'DRAFT'
       AND (
           NEW.contract_id <> OLD.contract_id
           OR NEW.room_id <> OLD.room_id
           OR NEW.tenant_profile_id <> OLD.tenant_profile_id
       )
       AND NOT EXISTS (
           SELECT 1
             FROM rental_contracts c
            WHERE c.id = NEW.contract_id
              AND c.room_id = NEW.room_id
              AND c.primary_tenant_id = NEW.tenant_profile_id
              AND c.status = 'ACTIVE'
              AND c.is_deleted = FALSE
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invoice must match an ACTIVE contract, room and primary tenant';
    END IF;

    IF OLD.status <> 'DRAFT'
       AND (
           NEW.contract_id <> OLD.contract_id
           OR NEW.room_id <> OLD.room_id
           OR NEW.tenant_profile_id <> OLD.tenant_profile_id
           OR NEW.billing_month <> OLD.billing_month
           OR NEW.billing_year <> OLD.billing_year
           OR NEW.due_date <> OLD.due_date
           OR NEW.total_amount <> OLD.total_amount
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An issued invoice cannot be edited directly';
    END IF;

    IF OLD.status = 'DRAFT' AND NEW.status = 'ISSUED' THEN
        IF NEW.total_amount <= 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An invoice must contain a positive total before issue';
        END IF;

        IF NEW.issue_date IS NULL THEN
            SET NEW.issue_date = CURRENT_DATE;
        END IF;

        SET NEW.issued_at = COALESCE(NEW.issued_at, CURRENT_TIMESTAMP(6));
    END IF;

    IF NEW.status = 'CANCELLED' AND OLD.status <> 'CANCELLED' THEN
        IF EXISTS (
            SELECT 1
              FROM payments
             WHERE invoice_id = NEW.id
               AND status = 'CONFIRMED'
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An invoice with confirmed payments cannot be cancelled';
        END IF;

        IF NEW.cancellation_reason IS NULL OR TRIM(NEW.cancellation_reason) = '' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Invoice cancellation reason is required';
        END IF;

        SET NEW.cancelled_at = COALESCE(NEW.cancelled_at, CURRENT_TIMESTAMP(6));
    END IF;
END$$

CREATE TRIGGER trg_invoices_lock_readings_au
AFTER UPDATE ON invoices
FOR EACH ROW
BEGIN
    IF OLD.status = 'DRAFT' AND NEW.status = 'ISSUED' THEN
        UPDATE meter_readings mr
        JOIN invoice_items ii ON ii.meter_reading_id = mr.id
           SET mr.status = 'LOCKED',
               mr.updated_at = CURRENT_TIMESTAMP(6),
               mr.updated_by = NEW.updated_by
         WHERE ii.invoice_id = NEW.id
           AND ii.is_deleted = FALSE;
    END IF;

    IF OLD.status <> 'CANCELLED' AND NEW.status = 'CANCELLED' THEN
        UPDATE meter_readings mr
        JOIN invoice_items ii ON ii.meter_reading_id = mr.id
           SET mr.status = 'DRAFT',
               mr.updated_at = CURRENT_TIMESTAMP(6),
               mr.updated_by = NEW.updated_by
         WHERE ii.invoice_id = NEW.id
           AND ii.is_deleted = FALSE;
    END IF;
END$$

-- ============================================================
-- Triggers: payments
-- ============================================================

CREATE TRIGGER trg_payments_validate_bi
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_invoice_total DECIMAL(18,2);
    DECLARE v_current_paid DECIMAL(18,2);
    DECLARE v_invoice_status VARCHAR(30);

    SELECT total_amount, status
      INTO v_invoice_total, v_invoice_status
      FROM invoices
     WHERE id = NEW.invoice_id
       AND is_deleted = FALSE;

    IF v_invoice_status IN ('DRAFT', 'CANCELLED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Payment can only be recorded for an issued invoice';
    END IF;

    IF NEW.status <> 'CONFIRMED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A new payment must start as CONFIRMED';
    END IF;

    SELECT COALESCE(SUM(amount), 0)
      INTO v_current_paid
      FROM payments
     WHERE invoice_id = NEW.invoice_id
       AND status = 'CONFIRMED';

    IF v_current_paid + NEW.amount > v_invoice_total THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total confirmed payments cannot exceed invoice total';
    END IF;
END$$

CREATE TRIGGER trg_payments_validate_bu
BEFORE UPDATE ON payments
FOR EACH ROW
BEGIN
    IF NEW.invoice_id <> OLD.invoice_id
       OR NEW.amount <> OLD.amount
       OR NEW.payment_date <> OLD.payment_date
       OR NEW.method <> OLD.method
       OR NOT (NEW.transaction_reference <=> OLD.transaction_reference) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Confirmed payment data is immutable; cancel it instead';
    END IF;

    IF OLD.status = 'CANCELLED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A cancelled payment cannot be changed';
    END IF;

    IF OLD.status = 'CONFIRMED' AND NEW.status = 'CANCELLED' THEN
        IF NEW.cancelled_at IS NULL
           OR NEW.cancelled_by IS NULL
           OR NEW.cancellation_reason IS NULL
           OR TRIM(NEW.cancellation_reason) = '' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Payment cancellation metadata is required';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_payments_recalculate_ai
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    CALL sp_recalculate_invoice_payment(NEW.invoice_id);
END$$

CREATE TRIGGER trg_payments_recalculate_au
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    CALL sp_recalculate_invoice_payment(NEW.invoice_id);
END$$

CREATE TRIGGER trg_payments_no_delete_bd
BEFORE DELETE ON payments
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payments cannot be deleted; cancel the payment instead';
END$$

-- ============================================================
-- Triggers: maintenance validation
-- ============================================================

CREATE TRIGGER trg_maintenance_requests_validate_bi
BEFORE INSERT ON maintenance_requests
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM rental_contracts c
          JOIN tenant_profiles tp ON tp.id = c.primary_tenant_id
         WHERE c.id = NEW.contract_id
           AND c.room_id = NEW.room_id
           AND c.status = 'ACTIVE'
           AND c.is_deleted = FALSE
           AND tp.user_id = NEW.requester_user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tenant can only create a request for the currently rented room';
    END IF;
END$$

CREATE TRIGGER trg_maintenance_requests_validate_bu
BEFORE UPDATE ON maintenance_requests
FOR EACH ROW
BEGIN
    IF NEW.status = 'RESOLVED'
       AND (NEW.resolution_summary IS NULL OR TRIM(NEW.resolution_summary) = '') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A RESOLVED request requires a resolution summary';
    END IF;

    IF OLD.status <> 'OPEN'
       AND (
           NEW.title <> OLD.title
           OR NEW.description <> OLD.description
           OR NEW.priority <> OLD.priority
           OR NEW.contract_id <> OLD.contract_id
           OR NEW.room_id <> OLD.room_id
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Request content can only be edited while status is OPEN';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- Views for common API queries and dashboards
-- ============================================================

CREATE VIEW vw_active_contract_resident_count AS
SELECT
    c.id AS contract_id,
    c.room_id,
    c.primary_tenant_id,
    1 + COUNT(co.id) AS current_resident_count
FROM rental_contracts c
LEFT JOIN contract_occupants co
       ON co.contract_id = c.id
      AND co.move_out_date IS NULL
      AND co.is_deleted = FALSE
WHERE c.status = 'ACTIVE'
  AND c.is_deleted = FALSE
GROUP BY c.id, c.room_id, c.primary_tenant_id;

CREATE VIEW vw_room_current_tenant AS
SELECT
    r.id AS room_id,
    r.room_number,
    r.status AS room_status,
    f.floor_number,
    b.id AS building_id,
    b.name AS building_name,
    c.id AS contract_id,
    c.contract_code,
    c.start_date,
    c.end_date,
    tp.id AS tenant_profile_id,
    tp.full_name AS tenant_name,
    u.phone AS tenant_phone,
    u.email AS tenant_email
FROM rooms r
JOIN floors f ON f.id = r.floor_id
JOIN buildings b ON b.id = r.building_id
LEFT JOIN rental_contracts c
       ON c.room_id = r.id
      AND c.status = 'ACTIVE'
      AND c.is_deleted = FALSE
LEFT JOIN tenant_profiles tp ON tp.id = c.primary_tenant_id
LEFT JOIN users u ON u.id = tp.user_id
WHERE r.is_deleted = FALSE;

CREATE VIEW vw_invoice_balance AS
SELECT
    i.id AS invoice_id,
    i.invoice_number,
    i.contract_id,
    i.room_id,
    i.tenant_profile_id,
    i.billing_month,
    i.billing_year,
    i.due_date,
    i.status,
    i.total_amount,
    i.paid_amount,
    i.remaining_amount
FROM invoices i
WHERE i.is_deleted = FALSE
  AND i.status <> 'CANCELLED';

-- ============================================================
-- Seed data
-- ============================================================

INSERT INTO roles (code, name, description)
VALUES
    ('ADMIN', 'Administrator', 'Building owner or manager'),
    ('TENANT', 'Tenant', 'Primary tenant account')
    AS new_role
ON DUPLICATE KEY UPDATE
    name = new_role.name,
    description = new_role.description;

INSERT INTO services (code, name, unit, charge_type, description, status)
VALUES
    ('ELECTRICITY', 'Điện', 'kWh', 'METERED', 'Tiền điện theo chỉ số công tơ', 'ACTIVE'),
    ('WATER', 'Nước', 'm3', 'METERED', 'Tiền nước theo chỉ số công tơ', 'ACTIVE'),
    ('INTERNET', 'Internet', 'tháng', 'FIXED_PER_ROOM', 'Phí internet cố định theo phòng', 'ACTIVE'),
    ('TRASH', 'Rác', 'tháng', 'FIXED_PER_ROOM', 'Phí rác cố định theo phòng', 'ACTIVE'),
    ('PARKING', 'Gửi xe', 'người/tháng', 'FIXED_PER_PERSON', 'Phí gửi xe theo người', 'ACTIVE'),
    ('MANAGEMENT', 'Phí quản lý', 'tháng', 'FIXED_PER_ROOM', 'Phí quản lý cố định theo phòng', 'ACTIVE')
AS new_service
ON DUPLICATE KEY UPDATE
    name = new_service.name,
    unit = new_service.unit,
    charge_type = new_service.charge_type,
    description = new_service.description,
    status = new_service.status;

-- ============================================================
-- Operational notes
-- 1. Create the first ADMIN user from Spring Boot using BCrypt.
-- 2. Configure service_prices before generating invoices.
-- 3. Call sp_mark_overdue_invoices() daily from a Spring @Scheduled job.
-- 4. Generate invoice + items in one backend transaction.
-- 5. Tenant data authorization must still be checked in Spring Security.
-- ============================================================
