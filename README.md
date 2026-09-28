# Rental Building Room Management System

> Ứng dụng quản lý nhà trọ gồm giao diện Flutter cho web/thiết bị di động và REST API Spring Boot, sử dụng MySQL để lưu trữ dữ liệu.

## Tổng quan

Hệ thống hỗ trợ hai vai trò chính:

- **Admin / Chủ nhà:** quản lý phòng, khách thuê, hợp đồng, dịch vụ và đơn giá, chỉ số điện nước, hóa đơn, thanh toán, yêu cầu sửa chữa, thông báo và báo cáo doanh thu.
- **Khách thuê:** xem trang chủ và hợp đồng, tra cứu hóa đơn và thanh toán, theo dõi thông báo, quản lý một số thông tin hồ sơ và gửi/theo dõi yêu cầu sửa chữa.

## Công nghệ

| Thành phần | Công nghệ |
|---|---|
| Frontend | Flutter, Dart, Riverpod, GoRouter, Dio |
| Backend | Java 17, Spring Boot 3, Spring Security, JWT, Spring Data JPA |
| Cơ sở dữ liệu | MySQL 8+ |
| API docs | Swagger / OpenAPI |

## Cấu trúc repository

```text
managementRoom/
├── backend/       Spring Boot REST API, SQL schema/sample data, Postman collection
├── frontend/      Flutter application cho web và thiết bị di động
└── README.md      Hướng dẫn tổng quan và chạy toàn dự án
```

Backend được chia theo module nghiệp vụ như `auth`, `room`, `tenant`, `contract`, `invoice`, `payment`, `maintenance`, `meterreading`, `serviceitem`, `notification` và `dashboard`. Frontend có các màn hình riêng cho admin, khách thuê và xác thực; phần dùng chung gồm API client, router, theme, model và widget.

## Yêu cầu

- JDK 17
- Maven 3.8+
- MySQL 8+
- Flutter SDK theo constraint trong `frontend/pubspec.yaml` (Dart 3.12 trở lên)
- MySQL Workbench hoặc MySQL command-line client để cài dữ liệu ban đầu

## Cài đặt cơ sở dữ liệu

1. Khởi động MySQL Server.
2. Mở và chạy `backend/rental_management_mvp_mysql.sql` trong MySQL Workbench. Script này tạo database `rental_management_mvp` cùng schema cần thiết.
3. Để có dữ liệu thử nghiệm, chạy tiếp `backend/rental_management_mvp_sample_data.sql`.
4. Khi backend khởi động, Flyway tự áp dụng các migration trong `backend/src/main/resources/db/migration`.

Ứng dụng không dùng Hibernate để tự tạo schema (`ddl-auto: none`), vì vậy cần nạp schema ban đầu trước khi chạy backend.

Tài khoản có trong bộ sample data:

| Vai trò | Tên đăng nhập | Mật khẩu mẫu |
|---|---|---|
| Admin | `admin` | `Admin@123` |
| Khách thuê | `tenant01` | `Tenant@123` |
| Khách thuê | `tenant02` | `Tenant@123` |
| Khách thuê | `tenant03` | `Tenant@123` |

> Đây là tài khoản phục vụ môi trường phát triển/demo. Hãy đổi mật khẩu và cấu hình bí mật riêng khi triển khai ở môi trường khác.

## Cấu hình backend

Backend đọc cấu hình từ biến môi trường hoặc file `backend/.env` (file này không nên commit). Các biến thường dùng:

```dotenv
SERVER_PORT=8080
DB_URL=jdbc:mysql://localhost:3306/rental_management_mvp?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
DB_USERNAME=root
DB_PASSWORD=your_mysql_password
JWT_SECRET=replace-with-a-long-random-secret-at-least-32-characters
JWT_ACCESS_TOKEN_EXPIRATION_MINUTES=120
BOOTSTRAP_ADMIN_USERNAME=admin
BOOTSTRAP_ADMIN_PASSWORD=Admin@123
```

Email khôi phục mật khẩu mặc định bị tắt. Muốn bật gửi email, cấu hình SMTP và đặt `PASSWORD_RESET_MAIL_ENABLED=true`; các biến SMTP gồm `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `PASSWORD_RESET_FROM_ADDRESS` và `PASSWORD_RESET_FRONTEND_URL`. Không đưa mật khẩu SMTP hoặc JWT secret lên Git.

## Chạy dự án

Mở hai terminal tại thư mục repository.

### 1. Chạy backend

```powershell
cd backend
mvn spring-boot:run
```

Backend mặc định chạy tại `http://localhost:8080`. Swagger UI: `http://localhost:8080/swagger-ui.html`. Base URL API: `http://localhost:8080/api/v1`.

### 2. Chạy Flutter Web

```powershell
cd frontend
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Mở `http://localhost:3000` trên trình duyệt. Có thể dùng `flutter run -d chrome` để chạy trực tiếp bằng Chrome.

### Chạy trên Android emulator hoặc thiết bị thật

Địa chỉ API phải trỏ đến backend mà thiết bị có thể truy cập:

```powershell
# Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1

# Thiết bị thật: thay bằng địa chỉ LAN của máy đang chạy backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
```

Hai thiết bị cần truy cập được cùng mạng; thay `192.168.1.10` bằng IP LAN thực tế của máy phát triển.

## Kiểm thử API bằng Postman

Import collection và environment:

- `backend/postman/rental-management-api.postman_collection.json`
- `backend/postman/rental-management-local.postman_environment.json`

Chọn environment `Rental Management Local`, chạy request đăng nhập để lưu JWT, sau đó gọi các API admin, tenant hoặc notification trong collection.

## Một số lưu ý

- Frontend mặc định gọi `http://localhost:8080/api/v1`; dùng `API_BASE_URL` để đổi địa chỉ theo môi trường.
- API yêu cầu JWT cho hầu hết endpoint; backend phân quyền theo role `ADMIN` và `TENANT`.
- JWT logout hiện xóa thông tin phiên ở client, phù hợp với cấu hình API stateless.
- Cấu hình mặc định trong `application.yml` dành cho phát triển cục bộ; hãy thay thông tin database, JWT và email trước khi triển khai.

## Tài liệu thành phần

- [Backend README](backend/README.md)
- [Flutter README](frontend/README.md)
- [SQL schema](backend/rental_management_mvp_mysql.sql)
- [Sample data](backend/rental_management_mvp_sample_data.sql)
