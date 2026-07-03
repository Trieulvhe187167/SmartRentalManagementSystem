-- ============================================================
-- Rental Management MVP - Sample Data
-- DBMS: MySQL 8.0+
-- Run this file AFTER rental_management_mvp_mysql.sql
--
-- Demo accounts:
--   ADMIN  : admin / Admin@123
--   TENANT : tenant01 / Tenant@123
--   TENANT : tenant02 / Tenant@123
--   TENANT : tenant03 / Tenant@123
--
-- Notes:
--   1. All personal data below is fictional and used only for testing.
--   2. The script does not delete existing business data.
--   3. It uses stable business codes to avoid inserting duplicates.
-- ============================================================

USE rental_management_mvp;
SET NAMES utf8mb4;

START TRANSACTION;

-- ============================================================
-- 1. Reference data
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

SET @admin_role_id = (
    SELECT id FROM roles WHERE code = 'ADMIN' LIMIT 1
);
SET @tenant_role_id = (
    SELECT id FROM roles WHERE code = 'TENANT' LIMIT 1
);

-- ============================================================
-- 2. Users
-- ============================================================

-- BCrypt hash for password: Admin@123
INSERT INTO users (
    role_id, username, password_hash, phone, email,
    status, must_change_password, created_by, updated_by
)
SELECT
    @admin_role_id,
    'admin',
    '$2a$10$6pjRLhvdmUKs3iEcPpLD2.peU5XqmL1/VNLdc8mmSLaRKh9ByNtyS',
    '0900000001',
    'admin@rental-demo.local',
    'ACTIVE',
    FALSE,
    NULL,
    NULL
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'admin'
);

SET @admin_user_id = (
    SELECT id FROM users WHERE username = 'admin' LIMIT 1
);

-- BCrypt hash for password: Tenant@123
INSERT INTO users (
    role_id, username, password_hash, phone, email,
    status, must_change_password, created_by, updated_by
)
SELECT
    @tenant_role_id,
    'tenant01',
    '$2a$10$WnvMbQOhZV0kioZeJ/sq4eMjjKJ.wsEgGF0vizbbe9d5HHO3GSgv6',
    '0901000001',
    'tenant01@rental-demo.local',
    'ACTIVE',
    TRUE,
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'tenant01'
);

INSERT INTO users (
    role_id, username, password_hash, phone, email,
    status, must_change_password, created_by, updated_by
)
SELECT
    @tenant_role_id,
    'tenant02',
    '$2a$10$WnvMbQOhZV0kioZeJ/sq4eMjjKJ.wsEgGF0vizbbe9d5HHO3GSgv6',
    '0901000002',
    'tenant02@rental-demo.local',
    'ACTIVE',
    TRUE,
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'tenant02'
);

INSERT INTO users (
    role_id, username, password_hash, phone, email,
    status, must_change_password, created_by, updated_by
)
SELECT
    @tenant_role_id,
    'tenant03',
    '$2a$10$WnvMbQOhZV0kioZeJ/sq4eMjjKJ.wsEgGF0vizbbe9d5HHO3GSgv6',
    '0901000003',
    'tenant03@rental-demo.local',
    'ACTIVE',
    TRUE,
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'tenant03'
);

SET @tenant01_user_id = (
    SELECT id FROM users WHERE username = 'tenant01' LIMIT 1
);
SET @tenant02_user_id = (
    SELECT id FROM users WHERE username = 'tenant02' LIMIT 1
);
SET @tenant03_user_id = (
    SELECT id FROM users WHERE username = 'tenant03' LIMIT 1
);

-- ============================================================
-- 3. Building, floors and rooms
-- ============================================================

INSERT INTO buildings (
    code, name, address, phone,
    bank_name, bank_account_number, bank_account_name,
    bank_transfer_content_template,
    status, created_by, updated_by
)
SELECT
    'BLD-AN-PHUC',
    'Nhà trọ An Phúc',
    '123 Đường Nguyễn Văn A, Phường 1, Quận Bình Thạnh, TP. Hồ Chí Minh',
    '0900000001',
    'Vietcombank',
    '0123456789',
    'NGUYEN VAN QUAN LY',
    'TRO {ROOM} {MONTH}/{YEAR}',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM buildings WHERE code = 'BLD-AN-PHUC'
);

SET @building_id = (
    SELECT id FROM buildings WHERE code = 'BLD-AN-PHUC' LIMIT 1
);

INSERT INTO floors (
    building_id, floor_number, name, description,
    status, created_by, updated_by
)
SELECT
    @building_id, 1, 'Tầng 1', 'Khu phòng tầng trệt',
    'ACTIVE', @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM floors
    WHERE building_id = @building_id AND floor_number = 1
);

INSERT INTO floors (
    building_id, floor_number, name, description,
    status, created_by, updated_by
)
SELECT
    @building_id, 2, 'Tầng 2', 'Khu phòng tầng 2',
    'ACTIVE', @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM floors
    WHERE building_id = @building_id AND floor_number = 2
);

INSERT INTO floors (
    building_id, floor_number, name, description,
    status, created_by, updated_by
)
SELECT
    @building_id, 3, 'Tầng 3', 'Khu phòng tầng 3',
    'ACTIVE', @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM floors
    WHERE building_id = @building_id AND floor_number = 3
);

SET @floor1_id = (
    SELECT id FROM floors
    WHERE building_id = @building_id AND floor_number = 1
    LIMIT 1
);
SET @floor2_id = (
    SELECT id FROM floors
    WHERE building_id = @building_id AND floor_number = 2
    LIMIT 1
);
SET @floor3_id = (
    SELECT id FROM floors
    WHERE building_id = @building_id AND floor_number = 3
    LIMIT 1
);

INSERT INTO rooms (
    building_id, floor_id, room_number, area_m2,
    default_rent, default_deposit, max_occupants,
    description, status, created_by, updated_by
)
SELECT
    @building_id, @floor1_id, '101', 24.00,
    3500000.00, 3500000.00, 2,
    'Phòng có cửa sổ, khu bếp riêng', 'AVAILABLE',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE building_id = @building_id AND room_number = '101'
);

INSERT INTO rooms (
    building_id, floor_id, room_number, area_m2,
    default_rent, default_deposit, max_occupants,
    description, status, created_by, updated_by
)
SELECT
    @building_id, @floor1_id, '102', 22.00,
    3300000.00, 3300000.00, 2,
    'Phòng tiêu chuẩn tầng 1', 'AVAILABLE',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE building_id = @building_id AND room_number = '102'
);

INSERT INTO rooms (
    building_id, floor_id, room_number, area_m2,
    default_rent, default_deposit, max_occupants,
    description, status, created_by, updated_by
)
SELECT
    @building_id, @floor2_id, '201', 30.00,
    4200000.00, 4200000.00, 3,
    'Phòng rộng, có ban công', 'AVAILABLE',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE building_id = @building_id AND room_number = '201'
);

INSERT INTO rooms (
    building_id, floor_id, room_number, area_m2,
    default_rent, default_deposit, max_occupants,
    description, status, created_by, updated_by
)
SELECT
    @building_id, @floor2_id, '202', 28.00,
    4000000.00, 4000000.00, 3,
    'Phòng tiêu chuẩn tầng 2', 'AVAILABLE',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE building_id = @building_id AND room_number = '202'
);

INSERT INTO rooms (
    building_id, floor_id, room_number, area_m2,
    default_rent, default_deposit, max_occupants,
    description, status, created_by, updated_by
)
SELECT
    @building_id, @floor3_id, '301', 26.00,
    3800000.00, 3800000.00, 2,
    'Phòng đang sửa hệ thống điện', 'MAINTENANCE',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE building_id = @building_id AND room_number = '301'
);

INSERT INTO rooms (
    building_id, floor_id, room_number, area_m2,
    default_rent, default_deposit, max_occupants,
    description, status, created_by, updated_by
)
SELECT
    @building_id, @floor3_id, '302', 26.00,
    3800000.00, 3800000.00, 2,
    'Phòng tiêu chuẩn tầng 3', 'AVAILABLE',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rooms
    WHERE building_id = @building_id AND room_number = '302'
);

SET @room101_id = (
    SELECT id FROM rooms
    WHERE building_id = @building_id AND room_number = '101'
    LIMIT 1
);
SET @room102_id = (
    SELECT id FROM rooms
    WHERE building_id = @building_id AND room_number = '102'
    LIMIT 1
);
SET @room201_id = (
    SELECT id FROM rooms
    WHERE building_id = @building_id AND room_number = '201'
    LIMIT 1
);

-- ============================================================
-- 4. Tenant profiles and occupants
-- ============================================================

INSERT INTO tenant_profiles (
    user_id, full_name, date_of_birth,
    identity_type, identity_number,
    identity_issued_date, identity_issued_place,
    permanent_address,
    emergency_contact_name, emergency_contact_phone,
    status, created_by, updated_by
)
SELECT
    @tenant01_user_id,
    'Nguyễn Minh Anh',
    '2002-05-14',
    'CCCD',
    '079202001001',
    '2021-08-10',
    'Cục Cảnh sát QLHC về TTXH',
    'Thành phố Thủ Đức, TP. Hồ Chí Minh',
    'Nguyễn Văn Bình',
    '0911000001',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM tenant_profiles WHERE user_id = @tenant01_user_id
);

INSERT INTO tenant_profiles (
    user_id, full_name, date_of_birth,
    identity_type, identity_number,
    identity_issued_date, identity_issued_place,
    permanent_address,
    emergency_contact_name, emergency_contact_phone,
    status, created_by, updated_by
)
SELECT
    @tenant02_user_id,
    'Trần Hoàng Nam',
    '2001-11-22',
    'CCCD',
    '079201002002',
    '2021-12-15',
    'Cục Cảnh sát QLHC về TTXH',
    'Quận Gò Vấp, TP. Hồ Chí Minh',
    'Trần Thị Hoa',
    '0911000002',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM tenant_profiles WHERE user_id = @tenant02_user_id
);

INSERT INTO tenant_profiles (
    user_id, full_name, date_of_birth,
    identity_type, identity_number,
    identity_issued_date, identity_issued_place,
    permanent_address,
    emergency_contact_name, emergency_contact_phone,
    status, created_by, updated_by
)
SELECT
    @tenant03_user_id,
    'Lê Thu Trang',
    '2003-03-08',
    'CCCD',
    '079203003003',
    '2022-04-20',
    'Cục Cảnh sát QLHC về TTXH',
    'Quận 12, TP. Hồ Chí Minh',
    'Lê Văn Thành',
    '0911000003',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM tenant_profiles WHERE user_id = @tenant03_user_id
);

SET @tenant01_profile_id = (
    SELECT id FROM tenant_profiles WHERE user_id = @tenant01_user_id LIMIT 1
);
SET @tenant02_profile_id = (
    SELECT id FROM tenant_profiles WHERE user_id = @tenant02_user_id LIMIT 1
);
SET @tenant03_profile_id = (
    SELECT id FROM tenant_profiles WHERE user_id = @tenant03_user_id LIMIT 1
);

INSERT INTO occupants (
    full_name, date_of_birth, phone,
    identity_type, identity_number, permanent_address,
    status, created_by, updated_by
)
SELECT
    'Phạm Ngọc Lan',
    '2002-09-10',
    '0902000001',
    'CCCD',
    '079202004004',
    'Quận Tân Bình, TP. Hồ Chí Minh',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM occupants WHERE identity_number = '079202004004'
);

INSERT INTO occupants (
    full_name, date_of_birth, phone,
    identity_type, identity_number, permanent_address,
    status, created_by, updated_by
)
SELECT
    'Võ Quốc Huy',
    '2001-06-18',
    '0902000002',
    'CCCD',
    '079201005005',
    'Tỉnh Đồng Nai',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM occupants WHERE identity_number = '079201005005'
);

INSERT INTO occupants (
    full_name, date_of_birth, phone,
    identity_type, identity_number, permanent_address,
    status, created_by, updated_by
)
SELECT
    'Đặng Thị Mai',
    '2002-01-26',
    '0902000003',
    'CCCD',
    '079202006006',
    'Tỉnh Bình Dương',
    'ACTIVE',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM occupants WHERE identity_number = '079202006006'
);

SET @occupant_lan_id = (
    SELECT id FROM occupants WHERE identity_number = '079202004004' LIMIT 1
);
SET @occupant_huy_id = (
    SELECT id FROM occupants WHERE identity_number = '079201005005' LIMIT 1
);
SET @occupant_mai_id = (
    SELECT id FROM occupants WHERE identity_number = '079202006006' LIMIT 1
);

-- ============================================================
-- 5. Rental contracts
-- ============================================================

INSERT INTO rental_contracts (
    contract_code, room_id, primary_tenant_id,
    start_date, end_date,
    applied_rent, deposit_amount, monthly_due_day,
    terms, status, activated_at,
    created_by, updated_by
)
SELECT
    'CT-2026-001',
    @room101_id,
    @tenant01_profile_id,
    '2026-01-01',
    '2026-12-31',
    3500000.00,
    3500000.00,
    5,
    'Thanh toán tiền phòng trước ngày 05 hằng tháng.',
    'ACTIVE',
    '2026-01-01 08:00:00.000000',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rental_contracts WHERE contract_code = 'CT-2026-001'
);

INSERT INTO rental_contracts (
    contract_code, room_id, primary_tenant_id,
    start_date, end_date,
    applied_rent, deposit_amount, monthly_due_day,
    terms, status, activated_at,
    created_by, updated_by
)
SELECT
    'CT-2026-002',
    @room201_id,
    @tenant02_profile_id,
    '2026-03-01',
    '2027-02-28',
    4200000.00,
    4200000.00,
    5,
    'Không gây tiếng ồn sau 22 giờ.',
    'ACTIVE',
    '2026-03-01 08:00:00.000000',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rental_contracts WHERE contract_code = 'CT-2026-002'
);

INSERT INTO rental_contracts (
    contract_code, room_id, primary_tenant_id,
    start_date, end_date,
    applied_rent, deposit_amount, monthly_due_day,
    terms, status,
    created_by, updated_by
)
SELECT
    'CT-2026-003-DRAFT',
    @room102_id,
    @tenant03_profile_id,
    '2026-07-01',
    '2027-06-30',
    3300000.00,
    3300000.00,
    5,
    'Hợp đồng đang chờ xác nhận.',
    'DRAFT',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM rental_contracts WHERE contract_code = 'CT-2026-003-DRAFT'
);

SET @contract101_id = (
    SELECT id FROM rental_contracts WHERE contract_code = 'CT-2026-001' LIMIT 1
);
SET @contract201_id = (
    SELECT id FROM rental_contracts WHERE contract_code = 'CT-2026-002' LIMIT 1
);
SET @contract102_draft_id = (
    SELECT id FROM rental_contracts WHERE contract_code = 'CT-2026-003-DRAFT' LIMIT 1
);

INSERT INTO contract_occupants (
    contract_id, occupant_id, relationship_to_primary,
    move_in_date, move_out_date, notes,
    created_by, updated_by
)
SELECT
    @contract101_id,
    @occupant_lan_id,
    'Bạn cùng phòng',
    '2026-01-01',
    NULL,
    'Người ở cùng hiện tại',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM contract_occupants
    WHERE contract_id = @contract101_id AND occupant_id = @occupant_lan_id
);

INSERT INTO contract_occupants (
    contract_id, occupant_id, relationship_to_primary,
    move_in_date, move_out_date, notes,
    created_by, updated_by
)
SELECT
    @contract201_id,
    @occupant_huy_id,
    'Bạn cùng phòng',
    '2026-03-01',
    NULL,
    'Người ở cùng hiện tại',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM contract_occupants
    WHERE contract_id = @contract201_id AND occupant_id = @occupant_huy_id
);

INSERT INTO contract_occupants (
    contract_id, occupant_id, relationship_to_primary,
    move_in_date, move_out_date, notes,
    created_by, updated_by
)
SELECT
    @contract201_id,
    @occupant_mai_id,
    'Bạn cùng phòng',
    '2026-03-01',
    NULL,
    'Người ở cùng hiện tại',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM contract_occupants
    WHERE contract_id = @contract201_id AND occupant_id = @occupant_mai_id
);

-- ============================================================
-- 6. Service prices and contract services
-- ============================================================

SET @electricity_service_id = (
    SELECT id FROM services WHERE code = 'ELECTRICITY' LIMIT 1
);
SET @water_service_id = (
    SELECT id FROM services WHERE code = 'WATER' LIMIT 1
);
SET @internet_service_id = (
    SELECT id FROM services WHERE code = 'INTERNET' LIMIT 1
);
SET @trash_service_id = (
    SELECT id FROM services WHERE code = 'TRASH' LIMIT 1
);
SET @parking_service_id = (
    SELECT id FROM services WHERE code = 'PARKING' LIMIT 1
);
SET @management_service_id = (
    SELECT id FROM services WHERE code = 'MANAGEMENT' LIMIT 1
);

INSERT INTO service_prices (
    service_id, unit_price, effective_from, effective_to,
    notes, created_by, updated_by
)
SELECT
    @electricity_service_id, 3500.00, '2026-01-01', NULL,
    'Đơn giá điện áp dụng từ đầu năm 2026',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM service_prices
    WHERE service_id = @electricity_service_id
      AND effective_from = '2026-01-01'
);

INSERT INTO service_prices (
    service_id, unit_price, effective_from, effective_to,
    notes, created_by, updated_by
)
SELECT
    @water_service_id, 15000.00, '2026-01-01', NULL,
    'Đơn giá nước áp dụng từ đầu năm 2026',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM service_prices
    WHERE service_id = @water_service_id
      AND effective_from = '2026-01-01'
);

INSERT INTO service_prices (
    service_id, unit_price, effective_from, effective_to,
    notes, created_by, updated_by
)
SELECT
    @internet_service_id, 120000.00, '2026-01-01', NULL,
    'Phí internet theo phòng',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM service_prices
    WHERE service_id = @internet_service_id
      AND effective_from = '2026-01-01'
);

INSERT INTO service_prices (
    service_id, unit_price, effective_from, effective_to,
    notes, created_by, updated_by
)
SELECT
    @trash_service_id, 30000.00, '2026-01-01', NULL,
    'Phí thu gom rác theo phòng',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM service_prices
    WHERE service_id = @trash_service_id
      AND effective_from = '2026-01-01'
);

INSERT INTO service_prices (
    service_id, unit_price, effective_from, effective_to,
    notes, created_by, updated_by
)
SELECT
    @parking_service_id, 100000.00, '2026-01-01', NULL,
    'Phí gửi xe theo người mỗi tháng',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM service_prices
    WHERE service_id = @parking_service_id
      AND effective_from = '2026-01-01'
);

INSERT INTO service_prices (
    service_id, unit_price, effective_from, effective_to,
    notes, created_by, updated_by
)
SELECT
    @management_service_id, 50000.00, '2026-01-01', NULL,
    'Phí quản lý theo phòng',
    @admin_user_id, @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM service_prices
    WHERE service_id = @management_service_id
      AND effective_from = '2026-01-01'
);

-- Assign all active services to room 101 contract.
INSERT INTO contract_services (
    contract_id, service_id, start_date, end_date,
    status, notes, created_by, updated_by
)
SELECT
    @contract101_id,
    s.id,
    '2026-01-01',
    NULL,
    'ACTIVE',
    'Dịch vụ áp dụng cho hợp đồng CT-2026-001',
    @admin_user_id,
    @admin_user_id
FROM services s
WHERE s.code IN (
    'ELECTRICITY', 'WATER', 'INTERNET',
    'TRASH', 'PARKING', 'MANAGEMENT'
)
AND NOT EXISTS (
    SELECT 1
    FROM contract_services cs
    WHERE cs.contract_id = @contract101_id
      AND cs.service_id = s.id
      AND cs.status = 'ACTIVE'
      AND cs.is_deleted = FALSE
);

-- Assign all active services to room 201 contract.
INSERT INTO contract_services (
    contract_id, service_id, start_date, end_date,
    status, notes, created_by, updated_by
)
SELECT
    @contract201_id,
    s.id,
    '2026-03-01',
    NULL,
    'ACTIVE',
    'Dịch vụ áp dụng cho hợp đồng CT-2026-002',
    @admin_user_id,
    @admin_user_id
FROM services s
WHERE s.code IN (
    'ELECTRICITY', 'WATER', 'INTERNET',
    'TRASH', 'PARKING', 'MANAGEMENT'
)
AND NOT EXISTS (
    SELECT 1
    FROM contract_services cs
    WHERE cs.contract_id = @contract201_id
      AND cs.service_id = s.id
      AND cs.status = 'ACTIVE'
      AND cs.is_deleted = FALSE
);

-- Cache current service prices for invoice item generation.
SET @electricity_price = (
    SELECT unit_price
    FROM service_prices
    WHERE service_id = @electricity_service_id
      AND effective_from <= '2026-06-01'
      AND (effective_to IS NULL OR effective_to >= '2026-06-01')
      AND is_deleted = FALSE
    ORDER BY effective_from DESC
    LIMIT 1
);
SET @water_price = (
    SELECT unit_price
    FROM service_prices
    WHERE service_id = @water_service_id
      AND effective_from <= '2026-06-01'
      AND (effective_to IS NULL OR effective_to >= '2026-06-01')
      AND is_deleted = FALSE
    ORDER BY effective_from DESC
    LIMIT 1
);
SET @internet_price = (
    SELECT unit_price
    FROM service_prices
    WHERE service_id = @internet_service_id
      AND effective_from <= '2026-06-01'
      AND (effective_to IS NULL OR effective_to >= '2026-06-01')
      AND is_deleted = FALSE
    ORDER BY effective_from DESC
    LIMIT 1
);
SET @trash_price = (
    SELECT unit_price
    FROM service_prices
    WHERE service_id = @trash_service_id
      AND effective_from <= '2026-06-01'
      AND (effective_to IS NULL OR effective_to >= '2026-06-01')
      AND is_deleted = FALSE
    ORDER BY effective_from DESC
    LIMIT 1
);
SET @parking_price = (
    SELECT unit_price
    FROM service_prices
    WHERE service_id = @parking_service_id
      AND effective_from <= '2026-06-01'
      AND (effective_to IS NULL OR effective_to >= '2026-06-01')
      AND is_deleted = FALSE
    ORDER BY effective_from DESC
    LIMIT 1
);
SET @management_price = (
    SELECT unit_price
    FROM service_prices
    WHERE service_id = @management_service_id
      AND effective_from <= '2026-06-01'
      AND (effective_to IS NULL OR effective_to >= '2026-06-01')
      AND is_deleted = FALSE
    ORDER BY effective_from DESC
    LIMIT 1
);

-- ============================================================
-- 7. Meter readings for June 2026
-- ============================================================

INSERT INTO meter_readings (
    room_id, service_id, billing_month, billing_year,
    previous_reading, current_reading, reading_date,
    recorded_by, notes, status, updated_by
)
SELECT
    @room101_id, @electricity_service_id, 6, 2026,
    1200.000, 1285.000, '2026-06-01',
    @admin_user_id, 'Chỉ số điện phòng 101 tháng 06/2026',
    'DRAFT', @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM meter_readings
    WHERE room_id = @room101_id
      AND service_id = @electricity_service_id
      AND billing_year = 2026
      AND billing_month = 6
);

INSERT INTO meter_readings (
    room_id, service_id, billing_month, billing_year,
    previous_reading, current_reading, reading_date,
    recorded_by, notes, status, updated_by
)
SELECT
    @room101_id, @water_service_id, 6, 2026,
    320.000, 329.000, '2026-06-01',
    @admin_user_id, 'Chỉ số nước phòng 101 tháng 06/2026',
    'DRAFT', @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM meter_readings
    WHERE room_id = @room101_id
      AND service_id = @water_service_id
      AND billing_year = 2026
      AND billing_month = 6
);

INSERT INTO meter_readings (
    room_id, service_id, billing_month, billing_year,
    previous_reading, current_reading, reading_date,
    recorded_by, notes, status, updated_by
)
SELECT
    @room201_id, @electricity_service_id, 6, 2026,
    850.000, 960.000, '2026-06-01',
    @admin_user_id, 'Chỉ số điện phòng 201 tháng 06/2026',
    'DRAFT', @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM meter_readings
    WHERE room_id = @room201_id
      AND service_id = @electricity_service_id
      AND billing_year = 2026
      AND billing_month = 6
);

INSERT INTO meter_readings (
    room_id, service_id, billing_month, billing_year,
    previous_reading, current_reading, reading_date,
    recorded_by, notes, status, updated_by
)
SELECT
    @room201_id, @water_service_id, 6, 2026,
    210.000, 223.000, '2026-06-01',
    @admin_user_id, 'Chỉ số nước phòng 201 tháng 06/2026',
    'DRAFT', @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM meter_readings
    WHERE room_id = @room201_id
      AND service_id = @water_service_id
      AND billing_year = 2026
      AND billing_month = 6
);

SET @mr101_electricity_id = (
    SELECT id FROM meter_readings
    WHERE room_id = @room101_id
      AND service_id = @electricity_service_id
      AND billing_year = 2026
      AND billing_month = 6
    LIMIT 1
);
SET @mr101_water_id = (
    SELECT id FROM meter_readings
    WHERE room_id = @room101_id
      AND service_id = @water_service_id
      AND billing_year = 2026
      AND billing_month = 6
    LIMIT 1
);
SET @mr201_electricity_id = (
    SELECT id FROM meter_readings
    WHERE room_id = @room201_id
      AND service_id = @electricity_service_id
      AND billing_year = 2026
      AND billing_month = 6
    LIMIT 1
);
SET @mr201_water_id = (
    SELECT id FROM meter_readings
    WHERE room_id = @room201_id
      AND service_id = @water_service_id
      AND billing_year = 2026
      AND billing_month = 6
    LIMIT 1
);

-- ============================================================
-- 8. June 2026 invoices
-- ============================================================

INSERT INTO invoices (
    invoice_number, contract_id, room_id, tenant_profile_id,
    billing_month, billing_year, due_date,
    status, notes, created_by, updated_by
)
SELECT
    'INV-202606-101',
    @contract101_id,
    @room101_id,
    @tenant01_profile_id,
    6,
    2026,
    '2026-06-05',
    'DRAFT',
    'Hóa đơn phòng 101 tháng 06/2026',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM invoices WHERE invoice_number = 'INV-202606-101'
);

INSERT INTO invoices (
    invoice_number, contract_id, room_id, tenant_profile_id,
    billing_month, billing_year, due_date,
    status, notes, created_by, updated_by
)
SELECT
    'INV-202606-201',
    @contract201_id,
    @room201_id,
    @tenant02_profile_id,
    6,
    2026,
    '2026-06-05',
    'DRAFT',
    'Hóa đơn phòng 201 tháng 06/2026',
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM invoices WHERE invoice_number = 'INV-202606-201'
);

SET @invoice101_id = (
    SELECT id FROM invoices WHERE invoice_number = 'INV-202606-101' LIMIT 1
);
SET @invoice201_id = (
    SELECT id FROM invoices WHERE invoice_number = 'INV-202606-201' LIMIT 1
);

-- Cache invoice status before inserting line items.
-- This avoids MySQL error 1442: the invoice_items trigger updates invoices,
-- so an INSERT INTO invoice_items statement must not also read invoices.
SET @invoice101_is_draft = EXISTS (
    SELECT 1
    FROM invoices
    WHERE id = @invoice101_id
      AND status = 'DRAFT'
      AND is_deleted = FALSE
);

SET @invoice201_is_draft = EXISTS (
    SELECT 1
    FROM invoices
    WHERE id = @invoice201_id
      AND status = 'DRAFT'
      AND is_deleted = FALSE
);

-- Room 101 invoice items.
INSERT INTO invoice_items (
    invoice_id, item_type, description,
    quantity, unit, unit_price, amount, display_order,
    created_by, updated_by
)
SELECT
    @invoice101_id, 'RENT', 'Tiền thuê phòng tháng 06/2026',
    1.000, 'tháng', 3500000.00, 3500000.00, 1,
    @admin_user_id, @admin_user_id
WHERE @invoice101_is_draft = 1
AND NOT EXISTS (
    SELECT 1 FROM invoice_items
    WHERE invoice_id = @invoice101_id
      AND item_type = 'RENT'
      AND description = 'Tiền thuê phòng tháng 06/2026'
);

INSERT INTO invoice_items (
    invoice_id, item_type, service_id, contract_service_id,
    meter_reading_id, description,
    quantity, unit, unit_price, amount, display_order,
    created_by, updated_by
)
SELECT
    @invoice101_id,
    'METERED_SERVICE',
    @electricity_service_id,
    (
        SELECT id FROM contract_services
        WHERE contract_id = @contract101_id
          AND service_id = @electricity_service_id
          AND status = 'ACTIVE'
          AND is_deleted = FALSE
        LIMIT 1
    ),
    @mr101_electricity_id,
    'Tiền điện tháng 06/2026',
    85.000,
    'kWh',
    @electricity_price,
    85.000 * @electricity_price,
    2,
    @admin_user_id,
    @admin_user_id
WHERE @invoice101_is_draft = 1
AND NOT EXISTS (
    SELECT 1 FROM invoice_items
    WHERE invoice_id = @invoice101_id
      AND meter_reading_id = @mr101_electricity_id
);

INSERT INTO invoice_items (
    invoice_id, item_type, service_id, contract_service_id,
    meter_reading_id, description,
    quantity, unit, unit_price, amount, display_order,
    created_by, updated_by
)
SELECT
    @invoice101_id,
    'METERED_SERVICE',
    @water_service_id,
    (
        SELECT id FROM contract_services
        WHERE contract_id = @contract101_id
          AND service_id = @water_service_id
          AND status = 'ACTIVE'
          AND is_deleted = FALSE
        LIMIT 1
    ),
    @mr101_water_id,
    'Tiền nước tháng 06/2026',
    9.000,
    'm3',
    @water_price,
    9.000 * @water_price,
    3,
    @admin_user_id,
    @admin_user_id
WHERE @invoice101_is_draft = 1
AND NOT EXISTS (
    SELECT 1 FROM invoice_items
    WHERE invoice_id = @invoice101_id
      AND meter_reading_id = @mr101_water_id
);

INSERT INTO invoice_items (
    invoice_id, item_type, service_id, contract_service_id,
    description, quantity, unit, unit_price, amount,
    display_order, created_by, updated_by
)
SELECT
    @invoice101_id,
    'FIXED_SERVICE',
    s.id,
    cs.id,
    CASE s.code
        WHEN 'INTERNET' THEN 'Phí Internet tháng 06/2026'
        WHEN 'TRASH' THEN 'Phí rác tháng 06/2026'
        WHEN 'PARKING' THEN 'Phí gửi xe tháng 06/2026'
        WHEN 'MANAGEMENT' THEN 'Phí quản lý tháng 06/2026'
    END,
    CASE WHEN s.code = 'PARKING' THEN 2.000 ELSE 1.000 END,
    s.unit,
    CASE s.code
        WHEN 'INTERNET' THEN @internet_price
        WHEN 'TRASH' THEN @trash_price
        WHEN 'PARKING' THEN @parking_price
        WHEN 'MANAGEMENT' THEN @management_price
    END,
    CASE s.code
        WHEN 'INTERNET' THEN @internet_price
        WHEN 'TRASH' THEN @trash_price
        WHEN 'PARKING' THEN 2.000 * @parking_price
        WHEN 'MANAGEMENT' THEN @management_price
    END,
    CASE s.code
        WHEN 'INTERNET' THEN 4
        WHEN 'TRASH' THEN 5
        WHEN 'PARKING' THEN 6
        WHEN 'MANAGEMENT' THEN 7
    END,
    @admin_user_id,
    @admin_user_id
FROM services s
JOIN contract_services cs
  ON cs.service_id = s.id
 AND cs.contract_id = @contract101_id
 AND cs.status = 'ACTIVE'
 AND cs.is_deleted = FALSE
WHERE s.code IN ('INTERNET', 'TRASH', 'PARKING', 'MANAGEMENT')
  AND @invoice101_is_draft = 1
  AND NOT EXISTS (
      SELECT 1 FROM invoice_items ii
      WHERE ii.invoice_id = @invoice101_id
        AND ii.service_id = s.id
        AND ii.item_type = 'FIXED_SERVICE'
  );

-- Room 201 invoice items.
INSERT INTO invoice_items (
    invoice_id, item_type, description,
    quantity, unit, unit_price, amount, display_order,
    created_by, updated_by
)
SELECT
    @invoice201_id, 'RENT', 'Tiền thuê phòng tháng 06/2026',
    1.000, 'tháng', 4200000.00, 4200000.00, 1,
    @admin_user_id, @admin_user_id
WHERE @invoice201_is_draft = 1
AND NOT EXISTS (
    SELECT 1 FROM invoice_items
    WHERE invoice_id = @invoice201_id
      AND item_type = 'RENT'
      AND description = 'Tiền thuê phòng tháng 06/2026'
);

INSERT INTO invoice_items (
    invoice_id, item_type, service_id, contract_service_id,
    meter_reading_id, description,
    quantity, unit, unit_price, amount, display_order,
    created_by, updated_by
)
SELECT
    @invoice201_id,
    'METERED_SERVICE',
    @electricity_service_id,
    (
        SELECT id FROM contract_services
        WHERE contract_id = @contract201_id
          AND service_id = @electricity_service_id
          AND status = 'ACTIVE'
          AND is_deleted = FALSE
        LIMIT 1
    ),
    @mr201_electricity_id,
    'Tiền điện tháng 06/2026',
    110.000,
    'kWh',
    @electricity_price,
    110.000 * @electricity_price,
    2,
    @admin_user_id,
    @admin_user_id
WHERE @invoice201_is_draft = 1
AND NOT EXISTS (
    SELECT 1 FROM invoice_items
    WHERE invoice_id = @invoice201_id
      AND meter_reading_id = @mr201_electricity_id
);

INSERT INTO invoice_items (
    invoice_id, item_type, service_id, contract_service_id,
    meter_reading_id, description,
    quantity, unit, unit_price, amount, display_order,
    created_by, updated_by
)
SELECT
    @invoice201_id,
    'METERED_SERVICE',
    @water_service_id,
    (
        SELECT id FROM contract_services
        WHERE contract_id = @contract201_id
          AND service_id = @water_service_id
          AND status = 'ACTIVE'
          AND is_deleted = FALSE
        LIMIT 1
    ),
    @mr201_water_id,
    'Tiền nước tháng 06/2026',
    13.000,
    'm3',
    @water_price,
    13.000 * @water_price,
    3,
    @admin_user_id,
    @admin_user_id
WHERE @invoice201_is_draft = 1
AND NOT EXISTS (
    SELECT 1 FROM invoice_items
    WHERE invoice_id = @invoice201_id
      AND meter_reading_id = @mr201_water_id
);

INSERT INTO invoice_items (
    invoice_id, item_type, service_id, contract_service_id,
    description, quantity, unit, unit_price, amount,
    display_order, created_by, updated_by
)
SELECT
    @invoice201_id,
    'FIXED_SERVICE',
    s.id,
    cs.id,
    CASE s.code
        WHEN 'INTERNET' THEN 'Phí Internet tháng 06/2026'
        WHEN 'TRASH' THEN 'Phí rác tháng 06/2026'
        WHEN 'PARKING' THEN 'Phí gửi xe tháng 06/2026'
        WHEN 'MANAGEMENT' THEN 'Phí quản lý tháng 06/2026'
    END,
    CASE WHEN s.code = 'PARKING' THEN 3.000 ELSE 1.000 END,
    s.unit,
    CASE s.code
        WHEN 'INTERNET' THEN @internet_price
        WHEN 'TRASH' THEN @trash_price
        WHEN 'PARKING' THEN @parking_price
        WHEN 'MANAGEMENT' THEN @management_price
    END,
    CASE s.code
        WHEN 'INTERNET' THEN @internet_price
        WHEN 'TRASH' THEN @trash_price
        WHEN 'PARKING' THEN 3.000 * @parking_price
        WHEN 'MANAGEMENT' THEN @management_price
    END,
    CASE s.code
        WHEN 'INTERNET' THEN 4
        WHEN 'TRASH' THEN 5
        WHEN 'PARKING' THEN 6
        WHEN 'MANAGEMENT' THEN 7
    END,
    @admin_user_id,
    @admin_user_id
FROM services s
JOIN contract_services cs
  ON cs.service_id = s.id
 AND cs.contract_id = @contract201_id
 AND cs.status = 'ACTIVE'
 AND cs.is_deleted = FALSE
WHERE s.code IN ('INTERNET', 'TRASH', 'PARKING', 'MANAGEMENT')
  AND @invoice201_is_draft = 1
  AND NOT EXISTS (
      SELECT 1 FROM invoice_items ii
      WHERE ii.invoice_id = @invoice201_id
        AND ii.service_id = s.id
        AND ii.item_type = 'FIXED_SERVICE'
  );

-- Issue both invoices after all line items have been added.
UPDATE invoices
SET status = 'ISSUED',
    issue_date = '2026-06-01',
    issued_at = '2026-06-01 08:00:00.000000',
    updated_by = @admin_user_id
WHERE id IN (@invoice101_id, @invoice201_id)
  AND status = 'DRAFT';

-- ============================================================
-- 9. Payments
-- ============================================================

-- Full payment for room 101.
INSERT INTO payments (
    payment_number, invoice_id, amount, payment_date,
    method, transaction_reference, notes,
    status, confirmed_by, created_by, updated_by
)
SELECT
    'PAY-202606-101-01',
    @invoice101_id,
    4332500.00,
    '2026-06-03 09:15:00.000000',
    'BANK_TRANSFER',
    'VCB-20260603-101',
    'Thanh toán đầy đủ hóa đơn tháng 06/2026',
    'CONFIRMED',
    @admin_user_id,
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM payments WHERE payment_number = 'PAY-202606-101-01'
);

-- Partial payment for room 201.
INSERT INTO payments (
    payment_number, invoice_id, amount, payment_date,
    method, transaction_reference, notes,
    status, confirmed_by, created_by, updated_by
)
SELECT
    'PAY-202606-201-01',
    @invoice201_id,
    2000000.00,
    '2026-06-10 14:30:00.000000',
    'CASH',
    NULL,
    'Thanh toán một phần hóa đơn tháng 06/2026',
    'CONFIRMED',
    @admin_user_id,
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM payments WHERE payment_number = 'PAY-202606-201-01'
);

-- A mistaken payment is inserted and then cancelled to demonstrate audit history.
INSERT INTO payments (
    payment_number, invoice_id, amount, payment_date,
    method, transaction_reference, notes,
    status, confirmed_by, created_by, updated_by
)
SELECT
    'PAY-202606-201-ERR',
    @invoice201_id,
    500000.00,
    '2026-06-11 10:00:00.000000',
    'BANK_TRANSFER',
    'DEMO-WRONG-TRANSFER',
    'Giao dịch mẫu được ghi nhận nhầm',
    'CONFIRMED',
    @admin_user_id,
    @admin_user_id,
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM payments WHERE payment_number = 'PAY-202606-201-ERR'
);

UPDATE payments
SET status = 'CANCELLED',
    cancelled_at = '2026-06-11 10:30:00.000000',
    cancelled_by = @admin_user_id,
    cancellation_reason = 'Giao dịch được nhập nhầm để kiểm thử chức năng hủy.',
    updated_by = @admin_user_id
WHERE payment_number = 'PAY-202606-201-ERR'
  AND status = 'CONFIRMED';

-- ============================================================
-- 10. Maintenance requests and update history
-- ============================================================

INSERT INTO maintenance_requests (
    request_number, contract_id, room_id, requester_user_id,
    title, description, priority, status,
    submitted_at, created_by, updated_by
)
SELECT
    'MR-202606-001',
    @contract101_id,
    @room101_id,
    @tenant01_user_id,
    'Vòi nước trong phòng bị rò rỉ',
    'Vòi nước khu vực bếp bị rò nhẹ và cần được kiểm tra.',
    'MEDIUM',
    'OPEN',
    '2026-06-12 08:30:00.000000',
    @tenant01_user_id,
    @tenant01_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM maintenance_requests WHERE request_number = 'MR-202606-001'
);

INSERT INTO maintenance_requests (
    request_number, contract_id, room_id, requester_user_id,
    title, description, priority, status,
    submitted_at, created_by, updated_by
)
SELECT
    'MR-202606-002',
    @contract201_id,
    @room201_id,
    @tenant02_user_id,
    'Máy lạnh không làm mát',
    'Máy lạnh vẫn chạy nhưng không còn làm mát như bình thường.',
    'HIGH',
    'OPEN',
    '2026-06-20 19:10:00.000000',
    @tenant02_user_id,
    @tenant02_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM maintenance_requests WHERE request_number = 'MR-202606-002'
);

SET @request001_id = (
    SELECT id FROM maintenance_requests
    WHERE request_number = 'MR-202606-001'
    LIMIT 1
);
SET @request002_id = (
    SELECT id FROM maintenance_requests
    WHERE request_number = 'MR-202606-002'
    LIMIT 1
);

INSERT INTO maintenance_updates (
    request_id, old_status, new_status, content, created_at, created_by
)
SELECT
    @request001_id,
    NULL,
    'OPEN',
    'Người thuê đã gửi yêu cầu sửa chữa.',
    '2026-06-12 08:30:00.000000',
    @tenant01_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM maintenance_updates
    WHERE request_id = @request001_id
      AND new_status = 'OPEN'
      AND content = 'Người thuê đã gửi yêu cầu sửa chữa.'
);

UPDATE maintenance_requests
SET status = 'RESOLVED',
    received_at = '2026-06-12 09:00:00.000000',
    resolved_at = '2026-06-12 15:30:00.000000',
    resolution_summary = 'Đã thay gioăng cao su và kiểm tra lại vòi nước, không còn rò rỉ.',
    updated_by = @admin_user_id
WHERE id = @request001_id
  AND status = 'OPEN';

INSERT INTO maintenance_updates (
    request_id, old_status, new_status, content, created_at, created_by
)
SELECT
    @request001_id,
    'OPEN',
    'RESOLVED',
    'Đã thay gioăng cao su và hoàn tất xử lý.',
    '2026-06-12 15:30:00.000000',
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM maintenance_updates
    WHERE request_id = @request001_id
      AND new_status = 'RESOLVED'
      AND content = 'Đã thay gioăng cao su và hoàn tất xử lý.'
);

INSERT INTO maintenance_updates (
    request_id, old_status, new_status, content, created_at, created_by
)
SELECT
    @request002_id,
    NULL,
    'OPEN',
    'Người thuê đã gửi yêu cầu sửa chữa.',
    '2026-06-20 19:10:00.000000',
    @tenant02_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM maintenance_updates
    WHERE request_id = @request002_id
      AND new_status = 'OPEN'
      AND content = 'Người thuê đã gửi yêu cầu sửa chữa.'
);

UPDATE maintenance_requests
SET status = 'IN_PROGRESS',
    received_at = '2026-06-21 08:00:00.000000',
    updated_by = @admin_user_id
WHERE id = @request002_id
  AND status = 'OPEN';

INSERT INTO maintenance_updates (
    request_id, old_status, new_status, content, created_at, created_by
)
SELECT
    @request002_id,
    'OPEN',
    'IN_PROGRESS',
    'Đã tiếp nhận và hẹn kỹ thuật viên kiểm tra máy lạnh.',
    '2026-06-21 08:00:00.000000',
    @admin_user_id
WHERE NOT EXISTS (
    SELECT 1 FROM maintenance_updates
    WHERE request_id = @request002_id
      AND new_status = 'IN_PROGRESS'
      AND content = 'Đã tiếp nhận và hẹn kỹ thuật viên kiểm tra máy lạnh.'
);

-- ============================================================
-- 11. In-app notifications
-- ============================================================

INSERT INTO notifications (
    user_id, notification_type, title, message,
    related_entity_type, related_entity_id,
    is_read, read_at, created_at
)
SELECT
    @tenant01_user_id,
    'INVOICE_ISSUED',
    'Hóa đơn tháng 06/2026 đã được phát hành',
    'Hóa đơn phòng 101 có tổng tiền 4.332.500 VND.',
    'INVOICE',
    @invoice101_id,
    TRUE,
    '2026-06-02 08:00:00.000000',
    '2026-06-01 08:05:00.000000'
WHERE NOT EXISTS (
    SELECT 1 FROM notifications
    WHERE user_id = @tenant01_user_id
      AND notification_type = 'INVOICE_ISSUED'
      AND related_entity_type = 'INVOICE'
      AND related_entity_id = @invoice101_id
);

INSERT INTO notifications (
    user_id, notification_type, title, message,
    related_entity_type, related_entity_id,
    is_read, read_at, created_at
)
SELECT
    @tenant01_user_id,
    'PAYMENT_CONFIRMED',
    'Thanh toán đã được xác nhận',
    'Khoản thanh toán 4.332.500 VND cho hóa đơn tháng 06/2026 đã được xác nhận.',
    'PAYMENT',
    (
        SELECT id FROM payments
        WHERE payment_number = 'PAY-202606-101-01'
        LIMIT 1
    ),
    FALSE,
    NULL,
    '2026-06-03 09:16:00.000000'
WHERE NOT EXISTS (
    SELECT 1 FROM notifications n
    WHERE n.user_id = @tenant01_user_id
      AND n.notification_type = 'PAYMENT_CONFIRMED'
      AND n.related_entity_type = 'PAYMENT'
      AND n.related_entity_id = (
          SELECT id FROM payments
          WHERE payment_number = 'PAY-202606-101-01'
          LIMIT 1
      )
);

INSERT INTO notifications (
    user_id, notification_type, title, message,
    related_entity_type, related_entity_id,
    is_read, read_at, created_at
)
SELECT
    @tenant02_user_id,
    'INVOICE_OVERDUE',
    'Hóa đơn tháng 06/2026 còn công nợ',
    'Hóa đơn phòng 201 đã quá hạn và vẫn còn số tiền chưa thanh toán.',
    'INVOICE',
    @invoice201_id,
    FALSE,
    NULL,
    '2026-06-28 08:00:00.000000'
WHERE NOT EXISTS (
    SELECT 1 FROM notifications
    WHERE user_id = @tenant02_user_id
      AND notification_type = 'INVOICE_OVERDUE'
      AND related_entity_type = 'INVOICE'
      AND related_entity_id = @invoice201_id
);

INSERT INTO notifications (
    user_id, notification_type, title, message,
    related_entity_type, related_entity_id,
    is_read, read_at, created_at
)
SELECT
    @tenant02_user_id,
    'MAINTENANCE_STATUS_CHANGED',
    'Yêu cầu sửa chữa đang được xử lý',
    'Yêu cầu kiểm tra máy lạnh đã chuyển sang trạng thái đang xử lý.',
    'MAINTENANCE_REQUEST',
    @request002_id,
    FALSE,
    NULL,
    '2026-06-21 08:01:00.000000'
WHERE NOT EXISTS (
    SELECT 1 FROM notifications
    WHERE user_id = @tenant02_user_id
      AND notification_type = 'MAINTENANCE_STATUS_CHANGED'
      AND related_entity_type = 'MAINTENANCE_REQUEST'
      AND related_entity_id = @request002_id
);

-- Update overdue status according to the current database date.
CALL sp_mark_overdue_invoices();

COMMIT;

-- ============================================================
-- Verification queries
-- ============================================================

SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'tenant_profiles', COUNT(*) FROM tenant_profiles
UNION ALL
SELECT 'rental_contracts', COUNT(*) FROM rental_contracts
UNION ALL
SELECT 'service_prices', COUNT(*) FROM service_prices
UNION ALL
SELECT 'meter_readings', COUNT(*) FROM meter_readings
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'maintenance_requests', COUNT(*) FROM maintenance_requests
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;

SELECT
    invoice_number,
    status,
    total_amount,
    paid_amount,
    remaining_amount
FROM vw_invoice_balance
ORDER BY invoice_number;

SELECT
    room_number,
    room_status,
    contract_code,
    tenant_name
FROM vw_room_current_tenant
ORDER BY floor_number, room_number;
