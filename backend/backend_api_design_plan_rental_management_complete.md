# Complete Backend API Design Plan
## Project: Rental Building Room Management System

> Backend API plan for the MVP version of the rental room management system.  
> Backend stack: **Java Spring Boot + MySQL**  
> Frontend client: **Flutter/Dart mobile application**

---

## 1. MVP Scope Summary

The MVP is designed for **one rental building** with two official roles:

| Role | Description |
|---|---|
| `ADMIN` | Building owner or manager. Has permission to manage rooms, tenants, contracts, services, invoices, payments, maintenance requests, notifications, and dashboard data. |
| `TENANT` | Primary tenant account. Can view personal rental data, invoices, payment status, notifications, and create maintenance requests. |

The core business flow of the MVP is:

```text
Room → Tenant → Contract → Service/Meter Reading → Invoice → Payment → Debt → Maintenance Request
```

The backend must support the following main modules:

1. Authentication and Authorization
2. Building, Floor, and Room Management
3. Tenant Profile and Occupant Management
4. Rental Contract Management
5. Service and Service Price Management
6. Contract Service Management
7. Meter Reading Management
8. Invoice and Invoice Item Management
9. Payment and Debt Management
10. Maintenance Request Management
11. Notification Management
12. Admin and Tenant Dashboard

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Language | Java |
| Framework | Spring Boot |
| Database | MySQL 8.0+ |
| ORM | Spring Data JPA / Hibernate |
| Security | Spring Security + JWT |
| Validation | Jakarta Bean Validation |
| API Documentation | Swagger / OpenAPI |
| Migration | Flyway or Liquibase |
| Password Hashing | BCrypt |
| Build Tool | Maven or Gradle |
| Testing | JUnit, Mockito, Spring Boot Test, MockMvc |
| Deployment | Docker optional for backend and MySQL |

Recommended backend style:

```text
Controller → Service → Repository → Database
```

---

## 3. Database Alignment

The backend must follow the provided MySQL database schema. The main tables are:

| No. | Table | Purpose |
|---|---|---|
| 1 | `roles` | Stores system roles: ADMIN, TENANT |
| 2 | `users` | Stores login accounts and authentication data |
| 3 | `buildings` | Stores rental building information |
| 4 | `floors` | Stores floor information |
| 5 | `rooms` | Stores room information and room status |
| 6 | `tenant_profiles` | Stores primary tenant profile information |
| 7 | `occupants` | Stores occupants living with the primary tenant |
| 8 | `rental_contracts` | Stores room rental contracts |
| 9 | `contract_occupants` | Links contracts with occupants |
| 10 | `services` | Stores service definitions |
| 11 | `service_prices` | Stores price history of services |
| 12 | `contract_services` | Stores services applied to contracts |
| 13 | `meter_readings` | Stores electricity/water meter readings |
| 14 | `invoices` | Stores monthly invoices |
| 15 | `invoice_items` | Stores invoice item details |
| 16 | `payments` | Stores payment records |
| 17 | `maintenance_requests` | Stores tenant maintenance requests |
| 18 | `maintenance_updates` | Stores processing history of maintenance requests |
| 19 | `notifications` | Stores in-app notifications |

The schema also includes useful database views and procedures:

| Database Object | Purpose |
|---|---|
| `vw_active_contract_resident_count` | Counts current residents in active contracts |
| `vw_room_current_tenant` | Shows current tenant information of each room |
| `vw_invoice_balance` | Shows invoice balance and remaining debt |
| `sp_recalculate_invoice_payment(invoice_id)` | Recalculates paid amount and invoice status after payment changes |
| `sp_mark_overdue_invoices()` | Marks issued/partial invoices as overdue when due date has passed |

---

## 4. Backend Package Structure

Suggested package structure:

```text
com.example.rentalmanagement
├── RentalManagementApplication.java
├── common
│   ├── api
│   │   ├── ApiResponse.java
│   │   ├── PageResponse.java
│   │   └── ErrorResponse.java
│   ├── exception
│   │   ├── BusinessException.java
│   │   ├── NotFoundException.java
│   │   ├── UnauthorizedException.java
│   │   └── GlobalExceptionHandler.java
│   ├── security
│   │   ├── JwtTokenProvider.java
│   │   ├── JwtAuthenticationFilter.java
│   │   ├── CustomUserDetailsService.java
│   │   └── SecurityConfig.java
│   ├── audit
│   │   ├── AuditableEntity.java
│   │   └── AuditorAwareImpl.java
│   └── util
│       ├── MoneyUtils.java
│       ├── CodeGenerator.java
│       └── DateUtils.java
├── auth
│   ├── controller
│   ├── dto
│   ├── service
│   └── repository
├── user
├── building
├── room
├── tenant
├── contract
├── serviceitem
├── meterreading
├── invoice
├── payment
├── maintenance
├── notification
└── dashboard
```

Notes:

- The package name `serviceitem` is used instead of `service` to avoid confusion with the service layer.
- Common audit fields should map to `created_at`, `created_by`, `updated_at`, `updated_by`, `is_deleted`, and `deleted_at` where applicable.
- Financial values must use `BigDecimal`, not `double`.

---

## 5. API Design Standards

### 5.1 Base URL

```text
/api/v1
```

### 5.2 Standard Response Format

```json
{
  "success": true,
  "message": "Success",
  "data": {},
  "timestamp": "2026-06-28T10:30:00"
}
```

For paginated responses:

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "items": [],
    "page": 0,
    "size": 20,
    "totalItems": 100,
    "totalPages": 5
  }
}
```

### 5.3 Common HTTP Status Codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 201 | Created |
| 400 | Invalid request or validation error |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Resource not found |
| 409 | Business rule conflict |
| 500 | Internal server error |

### 5.4 Pagination Convention

```text
?page=0&size=20&sort=createdAt,desc
```

### 5.5 Role Convention

| Role | Backend Authority |
|---|---|
| ADMIN | `ROLE_ADMIN` |
| TENANT | `ROLE_TENANT` |

### 5.6 Authentication Header

```http
Authorization: Bearer <access_token>
```

---

## 6. Detailed Authentication, Token, Security, and Validation Design

This section adds the technical details required to implement a complete Spring Boot backend API, including login flow, JWT token rules, route protection, logout strategy, password rules, DTO validation, service-layer validation, CORS, Swagger, and global exception handling.

---

### 6.1 Authentication Scope for MVP

The current database schema contains `roles` and `users`, but it does not contain a `refresh_tokens` table. Therefore, the official MVP authentication strategy is:

| Item | MVP Decision |
|---|---|
| Login method | Username and password |
| Token type | JWT access token |
| Refresh token | Not included in MVP unless a new table is added |
| Logout behavior | Client-side logout by deleting token from Flutter secure storage |
| Password storage | BCrypt hash only |
| Role model | `ADMIN`, `TENANT` |
| Token storage in Flutter | `flutter_secure_storage` is recommended |

If the team later wants refresh token support, add a new table such as `refresh_tokens(id, user_id, token_hash, expires_at, revoked_at, created_at)`.

---

### 6.2 JWT Token Configuration

Suggested configuration in `application.yml`:

```yaml
app:
  security:
    jwt:
      secret: ${JWT_SECRET}
      access-token-expiration-minutes: 120
      issuer: rental-management-api
```

JWT payload should contain only necessary identity claims:

| Claim | Description |
|---|---|
| `sub` | Username |
| `userId` | Current user ID |
| `role` | `ADMIN` or `TENANT` |
| `status` | User account status |
| `mustChangePassword` | Whether user must change password after first login/reset |
| `iat` | Issued at |
| `exp` | Expiration time |
| `iss` | Token issuer |

Do not store password, identity number, phone number, or sensitive personal information in the token.

---

### 6.3 Login Flow

```text
1. Flutter sends username and password to POST /api/v1/auth/login
2. Backend validates request format
3. Backend loads user by username
4. Backend checks account status
5. Backend verifies password using BCrypt
6. Backend updates last_login_at
7. Backend generates JWT access token
8. Backend returns token and basic user information
9. Flutter stores token securely and sends it in Authorization header
```

#### Login API

```http
POST /api/v1/auth/login
Content-Type: application/json
```

Request:

```json
{
  "username": "tenant01",
  "password": "Password@123"
}
```

Success response:

```json
{
  "success": true,
  "message": "Login successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 7200,
    "userId": 2,
    "username": "tenant01",
    "role": "TENANT",
    "mustChangePassword": true
  },
  "timestamp": "2026-06-28T10:30:00"
}
```

Common login errors:

| Case | HTTP | Error Code |
|---|---:|---|
| Missing username or password | 400 | `VALIDATION_ERROR` |
| Wrong username or password | 401 | `AUTH_INVALID_CREDENTIALS` |
| Account locked | 401 | `AUTH_ACCOUNT_LOCKED` |
| Account inactive | 401 | `AUTH_ACCOUNT_INACTIVE` |

---

### 6.4 JWT Authentication Filter Flow

Every protected request must go through a JWT filter.

```text
Request
  ↓
JwtAuthenticationFilter
  ↓
Read Authorization header
  ↓
Validate Bearer token format
  ↓
Validate signature and expiration
  ↓
Load user from database
  ↓
Check user status = ACTIVE
  ↓
Create Authentication object
  ↓
Set SecurityContext
  ↓
Continue to Controller
```

If token is missing, invalid, expired, or the user is locked, the request must return `401 Unauthorized`.

---

### 6.5 Spring Security Route Protection

Recommended `SecurityFilterChain` logic:

```text
Permit all:
- POST /api/v1/auth/login
- /swagger-ui/**
- /v3/api-docs/**

Require ADMIN:
- /api/v1/admin/**

Require TENANT:
- /api/v1/tenant/**

Require authenticated user:
- /api/v1/auth/me
- /api/v1/auth/change-password
- /api/v1/notifications/**
```

Example method-level security:

```java
@PreAuthorize("hasRole('ADMIN')")
@PostMapping("/admin/rooms")
public ApiResponse<RoomResponse> createRoom(@Valid @RequestBody RoomCreateRequest request) {
    return ApiResponse.success(roomService.createRoom(request));
}
```

Tenant data access must still be checked in the service layer. Route-level security alone is not enough.

---

### 6.6 Logout Strategy

Since the MVP does not use refresh tokens or token blacklist, logout is handled as follows:

| Side | Behavior |
|---|---|
| Flutter | Deletes access token from secure storage |
| Backend | Returns success response for `/auth/logout` but does not invalidate JWT server-side |

Endpoint:

```http
POST /api/v1/auth/logout
Authorization: Bearer <access_token>
```

Response:

```json
{
  "success": true,
  "message": "Logout successfully",
  "data": null,
  "timestamp": "2026-06-28T10:30:00"
}
```

Security note: Use short access token expiration time. If server-side logout is required, add a token blacklist or refresh token table.

---

### 6.7 Password Policy

| Rule | Requirement |
|---|---|
| Minimum length | 8 characters |
| Maximum length | 72 characters before BCrypt hashing |
| Complexity | At least 1 letter and 1 number |
| Storage | Store only `password_hash` |
| Reset password | Set `must_change_password = TRUE` |
| Change password | User must provide old password |
| Plain text password | Must never be stored or logged |

Suggested validation message:

```text
Password must be 8–72 characters and contain at least one letter and one number.
```

---

### 6.8 DTO Validation Design

Use Jakarta Bean Validation annotations in request DTOs.

#### Common validation annotations

| Annotation | Use case |
|---|---|
| `@NotBlank` | Required text fields |
| `@NotNull` | Required object/ID/date/number fields |
| `@Email` | Email field |
| `@Size` | String length limit |
| `@Pattern` | Phone, username, password, code format |
| `@Min` / `@Max` | Integer ranges |
| `@DecimalMin` | Money and numeric values |
| `@Past` | Date of birth |
| `@Future` / `@FutureOrPresent` | Future-related dates |
| `@Valid` | Nested object validation |

---

### 6.9 Main Request DTO Validation Rules

#### Auth DTOs

| DTO | Field | Validation |
|---|---|---|
| `LoginRequest` | `username` | `@NotBlank`, `@Size(max = 100)` |
| `LoginRequest` | `password` | `@NotBlank`, `@Size(max = 72)` |
| `ChangePasswordRequest` | `oldPassword` | `@NotBlank` |
| `ChangePasswordRequest` | `newPassword` | `@NotBlank`, password policy pattern |
| `ChangePasswordRequest` | `confirmPassword` | Must match `newPassword` |
| `ResetPasswordRequest` | `newPassword` | `@NotBlank`, password policy pattern |

#### User and tenant account DTOs

| DTO | Field | Validation |
|---|---|---|
| `CreateTenantAccountRequest` | `username` | `@NotBlank`, unique |
| `CreateTenantAccountRequest` | `phone` | Valid phone format, unique if not null |
| `CreateTenantAccountRequest` | `email` | `@Email`, unique if not null |
| `CreateTenantAccountRequest` | `temporaryPassword` | Password policy |

#### Building/Floor/Room DTOs

| DTO | Field | Validation |
|---|---|---|
| `BuildingRequest` | `code` | `@NotBlank`, unique |
| `BuildingRequest` | `name` | `@NotBlank`, `@Size(max = 150)` |
| `BuildingRequest` | `address` | `@NotBlank`, `@Size(max = 500)` |
| `FloorRequest` | `buildingId` | `@NotNull` |
| `FloorRequest` | `floorNumber` | Required, unique in building |
| `RoomCreateRequest` | `buildingId` | `@NotNull` |
| `RoomCreateRequest` | `floorId` | `@NotNull` |
| `RoomCreateRequest` | `roomNumber` | `@NotBlank`, unique in building |
| `RoomCreateRequest` | `areaM2` | `@DecimalMin(value = "0.01")` |
| `RoomCreateRequest` | `defaultRent` | `@DecimalMin(value = "0.00")` |
| `RoomCreateRequest` | `defaultDeposit` | `@DecimalMin(value = "0.00")` |
| `RoomCreateRequest` | `maxOccupants` | `@Min(1)` |

#### Tenant and occupant DTOs

| DTO | Field | Validation |
|---|---|---|
| `TenantProfileRequest` | `userId` | `@NotNull`, must belong to TENANT role |
| `TenantProfileRequest` | `fullName` | `@NotBlank` |
| `TenantProfileRequest` | `dateOfBirth` | `@NotNull`, `@Past` |
| `TenantProfileRequest` | `identityType` | Must be `CCCD`, `PASSPORT`, or `OTHER` |
| `TenantProfileRequest` | `identityNumber` | `@NotBlank`, unique |
| `TenantProfileRequest` | `permanentAddress` | `@NotBlank` |
| `OccupantRequest` | `fullName` | `@NotBlank` |
| `OccupantRequest` | `identityNumber` | Unique if not null |

#### Contract DTOs

| DTO | Field | Validation |
|---|---|---|
| `ContractCreateRequest` | `contractCode` | `@NotBlank`, unique |
| `ContractCreateRequest` | `roomId` | `@NotNull` |
| `ContractCreateRequest` | `primaryTenantId` | `@NotNull` |
| `ContractCreateRequest` | `startDate` | `@NotNull` |
| `ContractCreateRequest` | `endDate` | Must be after `startDate` |
| `ContractCreateRequest` | `appliedRent` | `@DecimalMin(value = "0.01")` |
| `ContractCreateRequest` | `depositAmount` | `@DecimalMin(value = "0.00")` |
| `ContractCreateRequest` | `monthlyDueDay` | `@Min(1)`, `@Max(31)` |
| `ContractOccupantRequest` | `occupantId` | `@NotNull` |
| `ContractOccupantRequest` | `relationshipToPrimary` | `@NotBlank` |
| `ContractOccupantRequest` | `moveInDate` | `@NotNull` |

#### Service and price DTOs

| DTO | Field | Validation |
|---|---|---|
| `ServiceRequest` | `code` | `@NotBlank`, unique |
| `ServiceRequest` | `name` | `@NotBlank` |
| `ServiceRequest` | `unit` | `@NotBlank` |
| `ServiceRequest` | `chargeType` | `METERED`, `FIXED_PER_ROOM`, `FIXED_PER_PERSON` |
| `ServicePriceRequest` | `unitPrice` | `@DecimalMin(value = "0.00")` |
| `ServicePriceRequest` | `effectiveFrom` | `@NotNull` |
| `ServicePriceRequest` | `effectiveTo` | Null or not before `effectiveFrom` |

#### Meter reading DTOs

| DTO | Field | Validation |
|---|---|---|
| `MeterReadingRequest` | `roomId` | `@NotNull` |
| `MeterReadingRequest` | `serviceId` | `@NotNull`, service must be `METERED` |
| `MeterReadingRequest` | `billingMonth` | `@Min(1)`, `@Max(12)` |
| `MeterReadingRequest` | `billingYear` | `@Min(2000)`, `@Max(2100)` |
| `MeterReadingRequest` | `previousReading` | `@DecimalMin(value = "0.000")` |
| `MeterReadingRequest` | `currentReading` | Must be >= previousReading |
| `MeterReadingRequest` | `readingDate` | `@NotNull` |

#### Invoice and payment DTOs

| DTO | Field | Validation |
|---|---|---|
| `GenerateInvoiceRequest` | `contractId` | `@NotNull` |
| `GenerateInvoiceRequest` | `billingMonth` | `@Min(1)`, `@Max(12)` |
| `GenerateInvoiceRequest` | `billingYear` | `@Min(2000)`, `@Max(2100)` |
| `InvoiceAdjustmentRequest` | `description` | `@NotBlank` |
| `InvoiceAdjustmentRequest` | `quantity` | `@DecimalMin(value = "0.000")` |
| `InvoiceAdjustmentRequest` | `unitPrice` | May be negative only for controlled adjustment logic |
| `PaymentCreateRequest` | `amount` | `@DecimalMin(value = "0.01")` |
| `PaymentCreateRequest` | `paymentDate` | `@NotNull` |
| `PaymentCreateRequest` | `method` | `CASH`, `BANK_TRANSFER`, `OTHER` |
| `PaymentCancelRequest` | `cancellationReason` | `@NotBlank` |

#### Maintenance DTOs

| DTO | Field | Validation |
|---|---|---|
| `MaintenanceRequestCreateRequest` | `contractId` | `@NotNull` |
| `MaintenanceRequestCreateRequest` | `roomId` | `@NotNull` |
| `MaintenanceRequestCreateRequest` | `title` | `@NotBlank`, `@Size(max = 200)` |
| `MaintenanceRequestCreateRequest` | `description` | `@NotBlank` |
| `MaintenanceRequestCreateRequest` | `priority` | `LOW`, `MEDIUM`, `HIGH`, `URGENT` |
| `MaintenanceStatusUpdateRequest` | `newStatus` | Required valid status |
| `MaintenanceStatusUpdateRequest` | `content` | `@NotBlank` |
| `MaintenanceStatusUpdateRequest` | `resolutionSummary` | Required when status is `RESOLVED` |
| `MaintenanceStatusUpdateRequest` | `rejectedReason` | Required when status is `REJECTED` |

---

### 6.10 Service-Layer Validation

DTO annotations only validate basic request format. Business rules must be checked in the service layer.

| Area | Service-layer validation |
|---|---|
| Login | User exists, password matches, status is `ACTIVE` |
| Room | Room number unique in building, floor belongs to same building |
| Tenant | User role must be `TENANT`, identity number unique |
| Contract | Room must be `AVAILABLE`, no active contract exists, resident count within capacity |
| Service Price | Price periods must not overlap for the same service |
| Meter Reading | Service must be `METERED`, no duplicate period, current >= previous |
| Invoice | Active contract required, no non-cancelled invoice for same period |
| Payment | Invoice not cancelled, amount <= remaining amount |
| Maintenance | Tenant owns current contract/room, status transition is valid |
| Notification | User can only mark own notification as read |

---

### 6.11 Global Exception Handling

Recommended exception classes:

```text
BusinessException
NotFoundException
ValidationException
UnauthorizedException
ForbiddenException
ConflictException
```

Validation error response example:

```json
{
  "success": false,
  "message": "Validation failed",
  "errorCode": "VALIDATION_ERROR",
  "details": [
    {
      "field": "roomNumber",
      "message": "Room number is required"
    },
    {
      "field": "defaultRent",
      "message": "Default rent must not be negative"
    }
  ],
  "timestamp": "2026-06-28T10:30:00"
}
```

---

### 6.12 CORS Configuration

Flutter mobile apps usually do not have browser CORS issues, but Flutter Web or Swagger testing may need CORS.

Suggested allowed origins for development:

```text
http://localhost:3000
http://localhost:5173
http://localhost:8080
```

Allowed methods:

```text
GET, POST, PUT, PATCH, DELETE, OPTIONS
```

Allowed headers:

```text
Authorization, Content-Type
```

In production, do not allow `*` unless required and reviewed.

---

### 6.13 Swagger/OpenAPI Design

Enable Swagger in development profile.

Suggested URL:

```text
/swagger-ui/index.html
/v3/api-docs
```

Each API should document:

| Item | Required |
|---|---|
| Endpoint summary | Yes |
| Required role | Yes |
| Request body schema | Yes |
| Response schema | Yes |
| Error responses | Yes |
| Example request/response | Recommended |

---

### 6.14 File Upload Decision

The current database schema does not include a general attachment table or image URL fields for meter readings and maintenance requests. Therefore, file upload is not included in the official MVP backend unless the database is extended.

If image upload is required later, add one of the following designs:

1. Add `image_url` fields to `meter_readings` and `maintenance_requests`; or
2. Add a generic `attachments` table:

```text
attachments(id, entity_type, entity_id, file_url, file_name, file_type, uploaded_by, created_at)
```

---

### 6.15 Logging and Audit

Backend should log important actions without exposing sensitive information.

| Should log | Should not log |
|---|---|
| User ID | Raw password |
| Endpoint path | JWT token value |
| Request method | Identity number in full |
| Business action | Bank account number in full |
| Error code | Personal sensitive data in full |

Audit fields in database should be filled automatically when possible:

```text
created_at, created_by, updated_at, updated_by, is_deleted, deleted_at
```

---

### 6.16 Validation and Security Testing Checklist

| Test group | Required tests |
|---|---|
| Auth | Login success, wrong password, locked account, expired token |
| Role security | Tenant cannot access `/admin/**`, Admin can access admin APIs |
| Tenant ownership | Tenant cannot view another tenant's invoice/contract/payment |
| Validation | Missing required fields, invalid enum, negative money, invalid dates |
| Contract | Cannot activate contract for occupied/maintenance room |
| Meter reading | Duplicate period rejected, current reading < previous rejected |
| Invoice | Duplicate invoice period rejected, issued invoice not editable |
| Payment | Payment cannot exceed remaining amount, cancelled payment recalculates invoice |
| Maintenance | Tenant can only edit/cancel OPEN request, RESOLVED requires summary |

---

## 7. Entity and Enum Mapping

### 7.1 Main Status Enums

```java
public enum UserStatus {
    ACTIVE, LOCKED, INACTIVE
}

public enum RoomStatus {
    AVAILABLE, OCCUPIED, MAINTENANCE, INACTIVE
}

public enum ContractStatus {
    DRAFT, ACTIVE, EXPIRED, TERMINATED, CANCELLED
}

public enum ServiceChargeType {
    METERED, FIXED_PER_ROOM, FIXED_PER_PERSON
}

public enum MeterReadingStatus {
    DRAFT, LOCKED, CANCELLED
}

public enum InvoiceStatus {
    DRAFT, ISSUED, PARTIALLY_PAID, PAID, OVERDUE, CANCELLED
}

public enum PaymentStatus {
    CONFIRMED, CANCELLED
}

public enum PaymentMethod {
    CASH, BANK_TRANSFER, OTHER
}

public enum MaintenanceStatus {
    OPEN, RECEIVED, IN_PROGRESS, RESOLVED, CANCELLED, REJECTED
}

public enum MaintenancePriority {
    LOW, MEDIUM, HIGH, URGENT
}
```

---

## 8. Module-by-Module API Plan

---

# 8.1 Authentication and User Management API

## Purpose

This module handles login, logout, password management, user account creation, account locking, and tenant account access.

## Main Tables

- `roles`
- `users`
- `tenant_profiles`

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| POST | `/auth/login` | Public | Login and receive JWT token |
| POST | `/auth/logout` | ADMIN/TENANT | Logout current user |
| GET | `/auth/me` | ADMIN/TENANT | Get current logged-in user profile |
| PUT | `/auth/change-password` | ADMIN/TENANT | Change own password |
| POST | `/admin/users/tenant-accounts` | ADMIN | Create tenant login account |
| PUT | `/admin/users/{id}/lock` | ADMIN | Lock a user account |
| PUT | `/admin/users/{id}/unlock` | ADMIN | Unlock a user account |
| PUT | `/admin/users/{id}/reset-password` | ADMIN | Reset password for a tenant |
| GET | `/admin/users` | ADMIN | Search and list user accounts |

## DTOs

```text
LoginRequest
- username
- password

LoginResponse
- accessToken
- tokenType
- userId
- username
- role
- mustChangePassword

ChangePasswordRequest
- oldPassword
- newPassword
- confirmPassword

CreateTenantAccountRequest
- username
- phone
- email
- temporaryPassword
```

## Business Rules

| Rule ID | Rule |
|---|---|
| AUTH-01 | Each username must be unique. |
| AUTH-02 | Each phone or email can belong to only one account. |
| AUTH-03 | Passwords must be stored using BCrypt hash. |
| AUTH-04 | A locked account cannot log in. |
| AUTH-05 | Users cannot choose their own role in MVP. |
| AUTH-06 | Public self-registration is not included in MVP. |

---

# 8.2 Building, Floor, and Room API

## Purpose

This module allows the ADMIN to manage the rental building, floors, and rooms.

## Main Tables

- `buildings`
- `floors`
- `rooms`
- `vw_room_current_tenant`

## Endpoints

### Building API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/buildings` | ADMIN | List buildings |
| GET | `/admin/buildings/{id}` | ADMIN | Get building detail |
| POST | `/admin/buildings` | ADMIN | Create building |
| PUT | `/admin/buildings/{id}` | ADMIN | Update building |
| PUT | `/admin/buildings/{id}/inactive` | ADMIN | Mark building inactive |

### Floor API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/floors` | ADMIN | List floors |
| GET | `/admin/buildings/{buildingId}/floors` | ADMIN | List floors by building |
| POST | `/admin/floors` | ADMIN | Create floor |
| PUT | `/admin/floors/{id}` | ADMIN | Update floor |
| PUT | `/admin/floors/{id}/inactive` | ADMIN | Mark floor inactive |

### Room API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/rooms` | ADMIN | List/search/filter rooms |
| GET | `/admin/rooms/{id}` | ADMIN | Get room detail |
| GET | `/admin/rooms/{id}/current-tenant` | ADMIN | Get current tenant of a room |
| POST | `/admin/rooms` | ADMIN | Create room |
| PUT | `/admin/rooms/{id}` | ADMIN | Update room information |
| PUT | `/admin/rooms/{id}/maintenance` | ADMIN | Set room status to MAINTENANCE |
| PUT | `/admin/rooms/{id}/inactive` | ADMIN | Set room status to INACTIVE |
| PUT | `/admin/rooms/{id}/available` | ADMIN | Set room status to AVAILABLE |

## Query Parameters for Room Search

```text
GET /admin/rooms?floorId=1&status=AVAILABLE&keyword=101&page=0&size=20
```

## DTOs

```text
RoomCreateRequest
- buildingId
- floorId
- roomNumber
- areaM2
- defaultRent
- defaultDeposit
- maxOccupants
- description

RoomResponse
- id
- roomNumber
- floorNumber
- areaM2
- defaultRent
- defaultDeposit
- maxOccupants
- status
- currentTenantName
- currentTenantPhone
```

## Business Rules

| Rule ID | Rule |
|---|---|
| ROOM-01 | Room number must be unique within the same building. |
| ROOM-02 | `OCCUPIED` rooms cannot have another active contract. |
| ROOM-03 | `MAINTENANCE` or `INACTIVE` rooms cannot be rented. |
| ROOM-04 | Rooms with existing contracts or invoices should not be hard-deleted. |
| ROOM-05 | When a contract becomes active, the room status automatically becomes `OCCUPIED`. |
| ROOM-06 | When a contract ends and no active contract remains, the room status becomes `AVAILABLE`. |

---

# 8.3 Tenant Profile and Occupant API

## Purpose

This module manages primary tenants and occupants living in a rented room.

## Main Tables

- `users`
- `tenant_profiles`
- `occupants`
- `contract_occupants`
- `rental_contracts`

## Endpoints

### Tenant Profile API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/tenants` | ADMIN | List/search tenants |
| GET | `/admin/tenants/{id}` | ADMIN | Get tenant profile detail |
| POST | `/admin/tenants` | ADMIN | Create tenant profile and link to user account |
| PUT | `/admin/tenants/{id}` | ADMIN | Update tenant profile |
| GET | `/admin/tenants/{id}/contracts` | ADMIN | View rental history of tenant |
| GET | `/tenant/profile` | TENANT | Tenant views own profile |

### Occupant API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/occupants` | ADMIN | List/search occupants |
| GET | `/admin/occupants/{id}` | ADMIN | Get occupant detail |
| POST | `/admin/occupants` | ADMIN | Create occupant profile |
| PUT | `/admin/occupants/{id}` | ADMIN | Update occupant profile |
| PUT | `/admin/contracts/{contractId}/occupants/{occupantId}/move-out` | ADMIN | Mark occupant as moved out |

## DTOs

```text
TenantProfileRequest
- userId
- fullName
- dateOfBirth
- identityType
- identityNumber
- identityIssuedDate
- identityIssuedPlace
- permanentAddress
- emergencyContactName
- emergencyContactPhone

OccupantRequest
- fullName
- dateOfBirth
- phone
- identityType
- identityNumber
- permanentAddress
```

## Business Rules

| Rule ID | Rule |
|---|---|
| TENANT-01 | A tenant profile must be linked to a TENANT account. |
| TENANT-02 | A contract must have exactly one primary tenant. |
| TENANT-03 | Current resident count must not exceed room capacity. |
| TENANT-04 | An occupant who moved out is not counted in per-person services. |
| TENANT-05 | Tenant or occupant history must not be hard-deleted after business usage. |

---

# 8.4 Rental Contract API

## Purpose

This module manages the rental contract lifecycle, including draft creation, activation, renewal, termination, and contract occupants.

## Main Tables

- `rental_contracts`
- `contract_occupants`
- `contract_services`
- `rooms`
- `tenant_profiles`
- `vw_active_contract_resident_count`

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/contracts` | ADMIN | List/search/filter contracts |
| GET | `/admin/contracts/{id}` | ADMIN | Get contract detail |
| POST | `/admin/contracts` | ADMIN | Create draft contract |
| PUT | `/admin/contracts/{id}` | ADMIN | Update draft contract |
| POST | `/admin/contracts/{id}/occupants` | ADMIN | Add occupant to contract |
| DELETE | `/admin/contracts/{id}/occupants/{occupantId}` | ADMIN | Remove occupant before activation or mark move out |
| POST | `/admin/contracts/{id}/services` | ADMIN | Assign service to contract |
| PUT | `/admin/contracts/{id}/activate` | ADMIN | Activate contract |
| PUT | `/admin/contracts/{id}/renew` | ADMIN | Renew contract |
| PUT | `/admin/contracts/{id}/terminate` | ADMIN | Terminate contract before end date |
| PUT | `/admin/contracts/{id}/expire` | ADMIN | Mark contract as expired |
| GET | `/tenant/contracts/current` | TENANT | Tenant views current contract |
| GET | `/tenant/contracts/history` | TENANT | Tenant views contract history |

## DTOs

```text
ContractCreateRequest
- contractCode
- roomId
- primaryTenantId
- startDate
- endDate
- appliedRent
- depositAmount
- monthlyDueDay
- terms

ContractActivateRequest
- confirm

ContractTerminateRequest
- endedAt
- terminationReason

ContractOccupantRequest
- occupantId
- relationshipToPrimary
- moveInDate
```

## Business Rules

| Rule ID | Rule |
|---|---|
| CONTRACT-01 | One room can have at most one `ACTIVE` contract. |
| CONTRACT-02 | Only `AVAILABLE` rooms can be activated in a contract. |
| CONTRACT-03 | End date must be after start date. |
| CONTRACT-04 | Active contract cannot directly change room. |
| CONTRACT-05 | If a tenant moves to another room, the old contract must be terminated and a new contract must be created. |
| CONTRACT-06 | Applied rent is stored in contract and must not change automatically when room default rent changes. |
| CONTRACT-07 | Contract with generated invoices must not be hard-deleted. |
| CONTRACT-08 | When contract is activated, room status becomes `OCCUPIED`. |
| CONTRACT-09 | When contract is ended and no active contract remains, room status becomes `AVAILABLE` or `MAINTENANCE`. |

## Transaction Notes

Contract activation must be executed inside one transaction:

```text
Validate room status
Validate primary tenant
Validate resident count
Validate contract dates
Set contract status = ACTIVE
Set activatedAt
Update room status = OCCUPIED
Create notification if needed
Commit transaction
```

---

# 8.5 Service and Price API

## Purpose

This module manages service definitions and price history. Service price is separated from service definition so that historical invoices are not affected when a price changes.

## Main Tables

- `services`
- `service_prices`
- `contract_services`

## Endpoints

### Service API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/services` | ADMIN | List services |
| GET | `/admin/services/{id}` | ADMIN | Get service detail |
| POST | `/admin/services` | ADMIN | Create service |
| PUT | `/admin/services/{id}` | ADMIN | Update service |
| PUT | `/admin/services/{id}/inactive` | ADMIN | Disable service |

### Service Price API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/services/{serviceId}/prices` | ADMIN | List price history of service |
| POST | `/admin/services/{serviceId}/prices` | ADMIN | Add new service price |
| PUT | `/admin/service-prices/{id}` | ADMIN | Update service price if allowed |

### Contract Service API

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/contracts/{contractId}/services` | ADMIN | List services applied to contract |
| POST | `/admin/contracts/{contractId}/services` | ADMIN | Add service to contract |
| PUT | `/admin/contract-services/{id}/inactive` | ADMIN | Stop using service in contract |

## DTOs

```text
ServiceRequest
- code
- name
- unit
- chargeType
- description

ServicePriceRequest
- unitPrice
- effectiveFrom
- effectiveTo
- notes

ContractServiceRequest
- serviceId
- startDate
- endDate
- notes
```

## Business Rules

| Rule ID | Rule |
|---|---|
| SERVICE-01 | Service code must be unique. |
| SERVICE-02 | Service used in invoices must not be hard-deleted. |
| SERVICE-03 | Changing service price must not change old invoices. |
| SERVICE-04 | Invoice items must store unit price at the time of invoice creation. |
| SERVICE-05 | One active contract can have only one active configuration for the same service. |
| SERVICE-06 | Per-person services are calculated based on current resident count in the billing period. |

---

# 8.6 Meter Reading API

## Purpose

This module manages electricity and water meter readings for services with charge type `METERED`.

## Main Tables

- `meter_readings`
- `rooms`
- `services`
- `users`

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/meter-readings` | ADMIN | List meter readings by room/service/month/year |
| GET | `/admin/meter-readings/{id}` | ADMIN | Get meter reading detail |
| GET | `/admin/rooms/{roomId}/meter-readings/latest` | ADMIN | Get latest reading of room |
| POST | `/admin/meter-readings` | ADMIN | Create meter reading |
| PUT | `/admin/meter-readings/{id}` | ADMIN | Update draft meter reading |
| PUT | `/admin/meter-readings/{id}/cancel` | ADMIN | Cancel meter reading |
| GET | `/tenant/meter-readings` | TENANT | Tenant views meter readings of current room |

## DTOs

```text
MeterReadingRequest
- roomId
- serviceId
- billingMonth
- billingYear
- previousReading
- currentReading
- readingDate
- notes
```

## Formula

```text
Consumption = CurrentReading - PreviousReading
Amount = Consumption × UnitPrice
```

## Business Rules

| Rule ID | Rule |
|---|---|
| METER-01 | Only services with charge type `METERED` can have meter readings. |
| METER-02 | Each room and service can have only one reading in the same billing period. |
| METER-03 | Current reading must be greater than or equal to previous reading. |
| METER-04 | Previous reading should default to previous period current reading. |
| METER-05 | Meter reading cannot be directly edited after invoice is issued. |
| METER-06 | To correct a locked reading, cancel the invoice, update the reading, and regenerate the invoice. |

---

# 8.7 Invoice API

## Purpose

This module generates and manages monthly invoices, including rent, metered services, fixed services, adjustments, and invoice status.

## Main Tables

- `invoices`
- `invoice_items`
- `rental_contracts`
- `contract_services`
- `meter_readings`
- `service_prices`
- `vw_invoice_balance`

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/invoices` | ADMIN | List/search/filter invoices |
| GET | `/admin/invoices/{id}` | ADMIN | Get invoice detail |
| POST | `/admin/invoices/generate-draft` | ADMIN | Generate draft invoice for one contract and period |
| POST | `/admin/invoices/generate-monthly` | ADMIN | Generate draft invoices for all active contracts in a period |
| PUT | `/admin/invoices/{id}/items` | ADMIN | Update invoice items while DRAFT |
| POST | `/admin/invoices/{id}/items/adjustment` | ADMIN | Add adjustment item while DRAFT |
| PUT | `/admin/invoices/{id}/issue` | ADMIN | Issue invoice |
| PUT | `/admin/invoices/{id}/cancel` | ADMIN | Cancel invoice if allowed |
| GET | `/tenant/invoices` | TENANT | Tenant views own invoices |
| GET | `/tenant/invoices/{id}` | TENANT | Tenant views own invoice detail |

## DTOs

```text
GenerateInvoiceRequest
- contractId
- billingMonth
- billingYear

GenerateMonthlyInvoicesRequest
- billingMonth
- billingYear

InvoiceAdjustmentRequest
- description
- amount
- unit
- quantity
- note

InvoiceIssueRequest
- issueDate
- dueDate
```

## Invoice Item Types

| Type | Description |
|---|---|
| `RENT` | Monthly room rent |
| `METERED_SERVICE` | Electricity/water based on meter consumption |
| `FIXED_SERVICE` | Internet, trash, management fee, parking, etc. |
| `ADJUSTMENT` | Manual increase or decrease |

## Invoice Generation Logic

```text
1. Validate active contract
2. Validate period has no non-cancelled invoice
3. Get rent from rental_contracts.applied_rent
4. Get active contract services
5. For METERED services: require meter_reading in the period
6. For FIXED_PER_ROOM services: quantity = 1
7. For FIXED_PER_PERSON services: quantity = resident count
8. Get effective service price for the billing period
9. Create invoice with status DRAFT
10. Create invoice_items
11. Database trigger recalculates invoice total_amount
```

## Business Rules

| Rule ID | Rule |
|---|---|
| INV-01 | Each active contract can have only one non-cancelled invoice in the same billing period. |
| INV-02 | Only active contracts can generate monthly invoices. |
| INV-03 | DRAFT invoices can be edited. |
| INV-04 | ISSUED invoices cannot be directly changed. |
| INV-05 | Invoice with payment records cannot be cancelled until payment records are handled. |
| INV-06 | Invoice total equals the sum of invoice items. |
| INV-07 | Due date is based on monthly due day in the contract. |
| INV-08 | Overdue issued or partially paid invoices must be marked `OVERDUE`. |
| INV-09 | MVP does not automatically prorate partial month rent. Admin can add adjustment item if needed. |

---

# 8.8 Payment and Debt API

## Purpose

This module manages payment confirmation, partial payments, debt tracking, and invoice payment status.

## Main Tables

- `payments`
- `invoices`
- `vw_invoice_balance`

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/payments` | ADMIN | List/search payments |
| GET | `/admin/payments/{id}` | ADMIN | Get payment detail |
| POST | `/admin/invoices/{invoiceId}/payments` | ADMIN | Record payment for invoice |
| PUT | `/admin/payments/{id}/cancel` | ADMIN | Cancel incorrect payment |
| GET | `/admin/debts` | ADMIN | View unpaid/overdue invoices |
| GET | `/tenant/payments` | TENANT | Tenant views payment history |
| GET | `/tenant/debt` | TENANT | Tenant views current debt |

## DTOs

```text
PaymentCreateRequest
- amount
- paymentDate
- method
- transactionReference
- notes

PaymentCancelRequest
- cancellationReason
```

## Business Rules

| Rule ID | Rule |
|---|---|
| PAY-01 | Payment amount must be greater than 0. |
| PAY-02 | Total confirmed payment must not exceed invoice total amount. |
| PAY-03 | One invoice can have multiple payments. |
| PAY-04 | If total paid amount equals invoice total, invoice status becomes `PAID`. |
| PAY-05 | If paid amount is greater than 0 but less than total, invoice status becomes `PARTIALLY_PAID`. |
| PAY-06 | Payments must be linked to a specific invoice. |
| PAY-07 | Payments must not be deleted. Incorrect payments must be cancelled. |
| PAY-08 | Only ADMIN can confirm or cancel payments. |
| PAY-09 | MVP does not integrate bank payment gateway. |

## Transaction Notes

When recording a payment:

```text
Validate invoice exists
Validate invoice is not CANCELLED
Validate amount <= remaining amount
Create payment with status CONFIRMED
Call sp_recalculate_invoice_payment(invoiceId)
Create PAYMENT_CONFIRMED notification for tenant
Commit transaction
```

---

# 8.9 Maintenance Request API

## Purpose

This module allows tenants to submit repair requests and allows ADMIN to receive, reject, process, and resolve requests.

## Main Tables

- `maintenance_requests`
- `maintenance_updates`
- `rental_contracts`
- `rooms`
- `users`

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| POST | `/tenant/maintenance-requests` | TENANT | Create maintenance request |
| GET | `/tenant/maintenance-requests` | TENANT | Tenant views own requests |
| GET | `/tenant/maintenance-requests/{id}` | TENANT | Tenant views own request detail |
| PUT | `/tenant/maintenance-requests/{id}` | TENANT | Edit request while OPEN |
| PUT | `/tenant/maintenance-requests/{id}/cancel` | TENANT | Cancel request while OPEN |
| GET | `/admin/maintenance-requests` | ADMIN | List/search/filter requests |
| GET | `/admin/maintenance-requests/{id}` | ADMIN | Get request detail |
| PUT | `/admin/maintenance-requests/{id}/receive` | ADMIN | Mark as RECEIVED |
| PUT | `/admin/maintenance-requests/{id}/in-progress` | ADMIN | Mark as IN_PROGRESS |
| PUT | `/admin/maintenance-requests/{id}/resolve` | ADMIN | Mark as RESOLVED |
| PUT | `/admin/maintenance-requests/{id}/reject` | ADMIN | Reject request |
| GET | `/admin/maintenance-requests/{id}/updates` | ADMIN | View request update history |

## DTOs

```text
MaintenanceRequestCreateRequest
- contractId
- roomId
- title
- description
- priority

MaintenanceStatusUpdateRequest
- newStatus
- content
- resolutionSummary
- rejectedReason
```

## Business Rules

| Rule ID | Rule |
|---|---|
| MAINT-01 | Tenant can only create request for their current rented room. |
| MAINT-02 | Tenant can edit or cancel request only when status is `OPEN`. |
| MAINT-03 | ADMIN is responsible for updating request status. |
| MAINT-04 | `RESOLVED` request must have resolution summary. |
| MAINT-05 | Maintenance cost is not automatically added to invoice in MVP. |
| MAINT-06 | If cost must be charged, ADMIN adds an adjustment item to invoice. |

---

# 8.10 Notification API

## Purpose

This module manages in-app notifications for tenants and admins.

## Main Table

- `notifications`

## Notification Types

| Type | Description |
|---|---|
| `INVOICE_ISSUED` | New invoice has been issued |
| `INVOICE_DUE_SOON` | Invoice is close to due date |
| `INVOICE_OVERDUE` | Invoice is overdue |
| `PAYMENT_CONFIRMED` | Payment has been confirmed |
| `CONTRACT_EXPIRING` | Contract is close to expiration |
| `MAINTENANCE_STATUS_CHANGED` | Maintenance request status changed |
| `GENERAL` | General notification |

## Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/notifications` | ADMIN/TENANT | Get current user's notifications |
| GET | `/notifications/unread-count` | ADMIN/TENANT | Count unread notifications |
| PUT | `/notifications/{id}/read` | ADMIN/TENANT | Mark one notification as read |
| PUT | `/notifications/read-all` | ADMIN/TENANT | Mark all notifications as read |
| POST | `/admin/notifications/general` | ADMIN | Send general notification to tenant |

## Business Rules

| Rule ID | Rule |
|---|---|
| NOTI-01 | Tenant only receives notifications related to their own data. |
| NOTI-02 | Each notification has read/unread status. |
| NOTI-03 | MVP uses in-app notifications only. |
| NOTI-04 | No SMS, email, or external push notification in MVP. |

---

# 8.11 Dashboard API

## Purpose

This module provides summary information for Admin and Tenant dashboards.

## Main Tables / Views

- `rooms`
- `rental_contracts`
- `invoices`
- `payments`
- `maintenance_requests`
- `vw_invoice_balance`
- `vw_room_current_tenant`

## Admin Dashboard Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/admin/dashboard/summary` | ADMIN | Get admin dashboard summary |
| GET | `/admin/dashboard/rooms` | ADMIN | Get room status statistics |
| GET | `/admin/dashboard/revenue` | ADMIN | Get monthly revenue and debt summary |
| GET | `/admin/dashboard/contracts-expiring` | ADMIN | Get contracts expiring soon |
| GET | `/admin/dashboard/open-maintenance` | ADMIN | Get open maintenance requests |

## Tenant Dashboard Endpoints

| Method | Endpoint | Role | Description |
|---|---|---|---|
| GET | `/tenant/dashboard` | TENANT | Get tenant dashboard summary |
| GET | `/tenant/current-room` | TENANT | Get current rented room |
| GET | `/tenant/current-invoice` | TENANT | Get latest invoice |
| GET | `/tenant/current-debt` | TENANT | Get unpaid amount |

## Admin Dashboard Response Example

```json
{
  "totalRooms": 30,
  "availableRooms": 5,
  "occupiedRooms": 22,
  "maintenanceRooms": 3,
  "occupancyRate": 73.33,
  "monthlyInvoiceAmount": 85000000,
  "monthlyCollectedAmount": 70000000,
  "totalDebt": 15000000,
  "openMaintenanceRequests": 4,
  "expiringContracts": 3
}
```

---

## 9. Security and Authorization Design

### 9.1 Public Endpoints

| Endpoint | Description |
|---|---|
| `/api/v1/auth/login` | Login |
| `/api/v1/swagger-ui/**` | API documentation, only enabled in development |

### 9.2 ADMIN-only Endpoints

All endpoints beginning with:

```text
/api/v1/admin/**
```

must require `ROLE_ADMIN`.

### 9.3 TENANT-only Endpoints

All endpoints beginning with:

```text
/api/v1/tenant/**
```

must require `ROLE_TENANT`.

### 9.4 Shared Authenticated Endpoints

```text
/api/v1/auth/me
/api/v1/auth/change-password
/api/v1/notifications/**
```

### 9.5 Tenant Data Security

Tenant authorization must be checked in the backend service layer. Do not rely only on hiding buttons in Flutter.

Required checks:

| Data | Rule |
|---|---|
| Contract | Tenant can only view contracts where they are the primary tenant |
| Invoice | Tenant can only view invoices linked to their tenant profile |
| Payment | Tenant can only view payments of their own invoices |
| Meter Reading | Tenant can only view readings of their current rented room |
| Maintenance Request | Tenant can only view or update their own requests |
| Notification | Tenant can only view their own notifications |

---

## 10. Scheduled Jobs

## 10.1 Mark Overdue Invoices Job

Runs daily.

```text
Call database procedure: sp_mark_overdue_invoices()
```

Suggested Spring implementation:

```java
@Scheduled(cron = "0 0 1 * * *")
public void markOverdueInvoices() {
    invoiceService.markOverdueInvoices();
}
```

## 10.2 Invoice Due Soon Notification Job

Runs daily.

Purpose:

- Find invoices due in 1–3 days.
- Create `INVOICE_DUE_SOON` notifications.

## 10.3 Contract Expiring Notification Job

Runs daily.

Purpose:

- Find contracts ending within the next 7–30 days.
- Create `CONTRACT_EXPIRING` notifications.

---

## 11. Transaction Design

The following operations must run inside database transactions:

| Operation | Reason |
|---|---|
| Activate contract | Updates contract and room status together |
| Terminate contract | Updates contract, room, occupants, and possibly final invoice |
| Generate invoice | Creates invoice and invoice items together |
| Issue invoice | Updates invoice status and locks related readings |
| Record payment | Creates payment and recalculates invoice balance |
| Cancel payment | Cancels payment and recalculates invoice balance |
| Resolve maintenance request | Updates request and creates maintenance update record |

Example annotation:

```java
@Transactional
public InvoiceResponse generateInvoice(GenerateInvoiceRequest request) {
    // Validate contract
    // Validate billing period
    // Create invoice
    // Create invoice items
    // Return response
}
```

---

## 12. Error Handling Design

## 12.1 Common Error Response

```json
{
  "success": false,
  "message": "Room is not available for rent",
  "errorCode": "ROOM_NOT_AVAILABLE",
  "details": [],
  "timestamp": "2026-06-28T10:30:00"
}
```

## 12.2 Suggested Business Error Codes

| Error Code | Meaning |
|---|---|
| `AUTH_INVALID_CREDENTIALS` | Username or password is incorrect |
| `AUTH_ACCOUNT_LOCKED` | Account is locked |
| `ROOM_NOT_FOUND` | Room does not exist |
| `ROOM_NOT_AVAILABLE` | Room cannot be rented |
| `CONTRACT_ACTIVE_EXISTS` | Room already has active contract |
| `CONTRACT_INVALID_DATE` | Contract date is invalid |
| `TENANT_NOT_FOUND` | Tenant profile does not exist |
| `CAPACITY_EXCEEDED` | Room resident count exceeds capacity |
| `SERVICE_PRICE_NOT_FOUND` | No effective service price found |
| `METER_READING_DUPLICATED` | Meter reading already exists for the period |
| `METER_READING_INVALID_INDEX` | Current index is smaller than previous index |
| `INVOICE_ALREADY_EXISTS` | Invoice already exists for the period |
| `INVOICE_NOT_EDITABLE` | Invoice cannot be edited in current status |
| `PAYMENT_EXCEEDS_REMAINING_AMOUNT` | Payment amount exceeds remaining debt |
| `MAINTENANCE_INVALID_STATUS` | Maintenance status transition is invalid |
| `ACCESS_DENIED` | User has no permission to access this resource |

---

## 13. API Development Backlog

## 13.1 Phase 1: Project Setup and Core Infrastructure

| Task | Description |
|---|---|
| BE-001 | Create Spring Boot project |
| BE-002 | Configure MySQL connection |
| BE-003 | Add database migration with provided SQL schema |
| BE-004 | Create common response and exception handler |
| BE-005 | Configure Swagger/OpenAPI |
| BE-006 | Configure Spring Security and JWT |
| BE-007 | Implement audit fields and soft delete support |

## 13.2 Phase 2: Authentication and User Management

| Task | Description |
|---|---|
| BE-101 | Implement login API |
| BE-102 | Implement current user profile API |
| BE-103 | Implement change password API |
| BE-104 | Implement create tenant account API |
| BE-105 | Implement lock/unlock user API |
| BE-106 | Implement reset password API |

## 13.3 Phase 3: Room and Tenant Management

| Task | Description |
|---|---|
| BE-201 | Implement building APIs |
| BE-202 | Implement floor APIs |
| BE-203 | Implement room CRUD APIs |
| BE-204 | Implement room search and filter API |
| BE-205 | Implement tenant profile APIs |
| BE-206 | Implement occupant APIs |

## 13.4 Phase 4: Contract and Service Management

| Task | Description |
|---|---|
| BE-301 | Implement contract draft creation |
| BE-302 | Implement contract update |
| BE-303 | Implement add/remove contract occupants |
| BE-304 | Implement contract activation |
| BE-305 | Implement contract termination and renewal |
| BE-306 | Implement service APIs |
| BE-307 | Implement service price APIs |
| BE-308 | Implement contract service APIs |

## 13.5 Phase 5: Meter Reading, Invoice, and Payment

| Task | Description |
|---|---|
| BE-401 | Implement meter reading APIs |
| BE-402 | Implement invoice draft generation API |
| BE-403 | Implement monthly invoice generation API |
| BE-404 | Implement invoice item adjustment API |
| BE-405 | Implement issue invoice API |
| BE-406 | Implement cancel invoice API |
| BE-407 | Implement payment recording API |
| BE-408 | Implement payment cancellation API |
| BE-409 | Implement debt list API |

## 13.6 Phase 6: Maintenance, Notification, and Dashboard

| Task | Description |
|---|---|
| BE-501 | Implement tenant maintenance request API |
| BE-502 | Implement admin maintenance management API |
| BE-503 | Implement maintenance update history API |
| BE-504 | Implement notification APIs |
| BE-505 | Implement admin dashboard APIs |
| BE-506 | Implement tenant dashboard APIs |
| BE-507 | Implement scheduled jobs |

## 13.7 Phase 7: Testing and Documentation

| Task | Description |
|---|---|
| BE-601 | Write unit tests for service logic |
| BE-602 | Write repository tests for important queries |
| BE-603 | Write integration tests for auth and business flows |
| BE-604 | Test invoice generation and payment workflows |
| BE-605 | Test tenant data authorization |
| BE-606 | Complete Swagger API documentation |
| BE-607 | Prepare Postman collection |

---

## 14. Testing Plan

## 14.1 Unit Tests

Focus:

- Contract validation
- Room status transition
- Resident count validation
- Meter reading calculation
- Invoice generation
- Payment status update
- Maintenance status transition

## 14.2 Integration Tests

Important flows:

1. Admin creates room and tenant.
2. Admin creates and activates contract.
3. Admin configures service price.
4. Admin records meter reading.
5. Admin generates and issues invoice.
6. Tenant views invoice.
7. Admin records partial payment.
8. Admin records full payment.
9. Tenant creates maintenance request.
10. Admin resolves maintenance request.

## 14.3 Security Tests

| Test Case | Expected Result |
|---|---|
| Tenant accesses another tenant invoice | 403 Forbidden |
| Tenant accesses admin room API | 403 Forbidden |
| Locked account logs in | 401 Unauthorized |
| Missing JWT token | 401 Unauthorized |
| Admin accesses management API | 200 Success |

---

## 15. API Implementation Priority

Recommended implementation order:

```text
1. Database migration
2. Auth + JWT
3. User + tenant profile
4. Building/floor/room
5. Contract
6. Service + price
7. Meter reading
8. Invoice
9. Payment
10. Maintenance request
11. Notification
12. Dashboard
13. Scheduled jobs
14. Testing and documentation
```

---

## 16. MVP Completion Criteria

The backend MVP is considered complete when the following scenario can run successfully through APIs:

1. ADMIN logs in.
2. ADMIN creates floor and room.
3. ADMIN creates tenant account and tenant profile.
4. ADMIN creates draft contract.
5. ADMIN adds occupants and contract services.
6. ADMIN activates contract.
7. Room status becomes `OCCUPIED`.
8. ADMIN configures service prices.
9. ADMIN records electricity and water readings.
10. ADMIN generates monthly invoice.
11. ADMIN issues invoice.
12. TENANT logs in and views the invoice.
13. ADMIN records partial or full payment.
14. Invoice paid amount and remaining amount are updated correctly.
15. TENANT creates a maintenance request.
16. ADMIN updates and resolves the request.
17. ADMIN terminates or expires contract.
18. Room status becomes `AVAILABLE` or `MAINTENANCE`.
19. Admin dashboard shows correct room count, revenue, and debt.

---

## 17. Notes for Flutter Integration

The Flutter application should consume backend APIs using JWT authentication.

Recommended mobile screens should map to backend modules:

| Flutter Screen | Backend API Module |
|---|---|
| Login Screen | Auth API |
| Admin Dashboard | Dashboard API |
| Room List / Detail | Room API |
| Tenant List / Detail | Tenant API |
| Contract List / Detail | Contract API |
| Service Management | Service API |
| Meter Reading Screen | Meter Reading API |
| Invoice List / Detail | Invoice API |
| Payment Recording | Payment API |
| Maintenance Request | Maintenance API |
| Notification Screen | Notification API |
| Tenant Dashboard | Tenant Dashboard API |

Frontend should store:

- Access token
- User role
- User ID
- Basic user profile

Frontend should not enforce business security alone. All permission checks must be repeated in backend.

---

## 18. Final Scope Statement

This backend API plan is based on the official MVP scope and the MySQL database schema of the Rental Building Room Management System. The backend focuses on one rental building with two roles, `ADMIN` and `TENANT`. It supports complete rental operations, including room management, tenant management, contracts, services, meter readings, invoices, payments, debts, maintenance requests, notifications, and dashboards.

The MVP does not include online payment gateway integration, electronic signature, SMS/email/push notification, IoT meter reading, AI prediction, public room booking, or complex multi-building management.
