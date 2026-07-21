# Rental Management Backend

Spring Boot backend API for the Rental Building Room Management MVP.

## Stack

- Java 17
- Spring Boot 3
- Spring Security + JWT
- Spring Data JPA / Hibernate
- MySQL 8+
- Swagger/OpenAPI

## Package Structure

Source code follows the module-oriented structure from the backend plan:

```text
com.example.rentalmanagement
├── common
│   ├── api
│   ├── audit
│   ├── enums
│   ├── exception
│   ├── scheduling
│   └── security
├── auth
├── building
├── contract
├── dashboard
├── invoice
├── maintenance
├── meterreading
├── notification
├── payment
├── room
├── serviceitem
├── tenant
└── user
```

Each business module is split into the relevant `controller`, `dto`, `repository`, and `service` packages where applicable.

## Database Setup

This project uses the existing MySQL schema in:

```text
rental_management_mvp_mysql.sql
```

Run the schema SQL file first. It creates database `rental_management_mvp`, all tables, views, stored procedures, triggers and reference data.

```powershell
mysql -u root -p < .\rental_management_mvp_mysql.sql
```

Then import the sample data file for local API testing:

```powershell
mysql -u root -p rental_management_mvp < .\rental_management_mvp_sample_data.sql
```

Demo accounts from the sample data:

```text
ADMIN  : admin / Admin@123
TENANT : tenant01 / Tenant@123
TENANT : tenant02 / Tenant@123
TENANT : tenant03 / Tenant@123
```

The app does not auto-create or migrate the schema. `spring.jpa.hibernate.ddl-auto` is `none`, so the SQL file remains the single database source of truth.

## Run Locally

Install JDK 17 and Maven, then run:

```powershell
$env:DB_URL="jdbc:mysql://localhost:3306/rental_management_mvp?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
$env:DB_USERNAME="root"
$env:DB_PASSWORD="sa123"
$env:JWT_SECRET="replace-with-a-long-secret-at-least-32-characters"
mvn spring-boot:run
```

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

Base API URL:

```text
http://localhost:8080/api/v1
```

## Postman

Import these files into Postman:

```text
postman/rental-management-api.postman_collection.json
postman/rental-management-local.postman_environment.json
```

Select the `Rental Management Local` environment, then run:

1. `Auth / Login Admin - save token`
2. Any request under `Admin`, `Tenant`, or `Notifications`

The login request saves the JWT into the `token` environment variable. The collection uses `Authorization: Bearer {{token}}` automatically.

## Bootstrap Admin

The SQL file seeds roles and services. On first startup, Spring Boot creates a default admin account if it does not exist. This default is aligned with the sample data:

```text
username: admin
password: Admin@123
```

Override with:

```powershell
$env:BOOTSTRAP_ADMIN_USERNAME="admin"
$env:BOOTSTRAP_ADMIN_PASSWORD="a-better-password"
```

## Notes

- The database triggers/procedures handle important rules such as room status updates, invoice totals and payment recalculation.
- Backend entities are mapped to the real schema columns, including `invoice_number`, `payment_number`, `request_number`, `notification_type`, `recorded_by`, `confirmed_by` and `requester_user_id`.
- Controllers expose the full MVP API surface from the plan: auth, users, buildings, floors, rooms, tenants, occupants, contracts, services, prices, contract services, meter readings, invoices, payments, maintenance, notifications and dashboards.
- Financial values use `BigDecimal`.
- JWT logout is client-side, matching the MVP plan.
- Audit logging is enabled through the `AUDIT` logger. It records request method, path, response status, authenticated user id, role, client IP and duration without logging request bodies, passwords or JWT tokens.
- JPA entity listeners fill `created_by` and `updated_by` when an authenticated user creates or updates auditable records.
