import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../models/admin_models.dart';
import '../models/room_models.dart';
import '../models/tenant_models.dart';
import '../models/contract_models.dart';
import '../models/meter_reading_models.dart';
import '../models/invoice_models.dart';
import '../models/payment_models.dart';
import '../models/maintenance_models.dart';
import '../models/notification_models.dart';
import '../models/service_models.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  final _dio = ApiClient.instance.dio;

  // ─── Dashboard ──────────────────────────────────────────────────────────────

  // GET /admin/dashboard
  Future<AdminDashboardResponse> dashboardSummary() async {
    try {
      final response = await _dio.get(ApiConstants.adminDashboard);
      final apiResponse = ApiResponse<AdminDashboardResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AdminDashboardResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/dashboard/room-stats
  Future<Map<String, int>> roomStats() async {
    try {
      final response = await _dio.get(ApiConstants.adminRoomStats);
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return apiResponse.data!.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/dashboard/revenue-summary
  Future<Map<String, double>> revenueSummary() async {
    try {
      final response = await _dio.get(ApiConstants.adminRevenueSummary);
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return apiResponse.data!.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/dashboard/expiring-contracts
  Future<List<RentalContract>> expiringContracts() async {
    try {
      final response = await _dio.get(ApiConstants.adminExpiringContracts);
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      return (apiResponse.data!)
          .map((e) => RentalContract.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Rooms ──────────────────────────────────────────────────────────────────

  Future<PageResponse<Building>> buildings({
    int page = 0,
    int size = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminBuildings,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Building>.fromJson(
        apiResponse.data!,
        (json) => Building.fromJson(json),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<PageResponse<Floor>> floors({
    int page = 0,
    int size = 100,
    int? buildingId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminFloors,
        queryParameters: {
          'page': page,
          'size': size,
          if (buildingId != null) 'buildingId': buildingId,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Floor>.fromJson(
        apiResponse.data!,
        (json) => Floor.fromJson(json),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/rooms
  Future<PageResponse<Room>> rooms({
    int page = 0,
    int size = 20,
    String? keyword,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminRooms,
        queryParameters: {
          'page': page,
          'size': size,
          if (keyword != null) 'keyword': keyword,
          if (status != null) 'status': status,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Room>.fromJson(
        apiResponse.data!,
        (json) => Room.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/rooms/{id}
  Future<Room> room(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminRooms}/$id');
      final apiResponse = ApiResponse<Room>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Room.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/rooms
  Future<Room> createRoom(RoomRequest req) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminRooms,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<Room>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Room.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/rooms/{id}
  Future<Room> updateRoom(int id, RoomRequest req) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminRooms}/$id',
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<Room>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Room.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/rooms/{id}/status
  Future<Room> updateRoomStatus(int id, String status) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminRooms}/$id/status',
        data: {'status': status},
      );
      final apiResponse = ApiResponse<Room>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Room.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/rooms/{id}/available
  Future<void> activateRoom(int id) async {
    try {
      await _dio.put('${ApiConstants.adminRooms}/$id/available');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/rooms/{id}/inactive
  Future<void> deactivateRoom(int id) async {
    try {
      await _dio.put('${ApiConstants.adminRooms}/$id/inactive');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Tenants ────────────────────────────────────────────────────────────────

  // GET /admin/tenants
  Future<PageResponse<TenantProfile>> tenants({
    int page = 0,
    int size = 20,
    String? keyword,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminTenants,
        queryParameters: {
          'page': page,
          'size': size,
          if (keyword != null) 'keyword': keyword,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<TenantProfile>.fromJson(
        apiResponse.data!,
        (json) => TenantProfile.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/tenants/{id}
  Future<TenantProfile> tenant(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminTenants}/$id');
      final apiResponse = ApiResponse<TenantProfile>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TenantProfile.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/tenants
  Future<TenantProfile> createTenant(TenantRequest req) async {
    try {
      var userId = req.userId;
      if (userId == null && req.username != null && req.password != null) {
        final accountResponse = await _dio.post(
          ApiConstants.adminTenantAccounts,
          data: req.toAccountJson(),
        );
        final accountApiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          accountResponse.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );
        userId = (accountApiResponse.data?['id'] as num?)?.toInt();
      }
      if (userId == null) {
        throw StateError('Cannot create tenant profile without a linked user.');
      }
      final response = await _dio.post(
        ApiConstants.adminTenants,
        data: req.toProfileJson(userId),
      );
      final apiResponse = ApiResponse<TenantProfile>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TenantProfile.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/tenants/{id}
  Future<TenantProfile> updateTenant(int id, TenantRequest req) async {
    try {
      final userId = req.userId;
      if (userId == null) {
        throw StateError('Cannot update tenant profile without a linked user.');
      }
      final response = await _dio.put(
        '${ApiConstants.adminTenants}/$id',
        data: req.toProfileJson(userId),
      );
      final apiResponse = ApiResponse<TenantProfile>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TenantProfile.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/users/{tenant.user.id}/lock
  Future<void> deactivateTenant(int id) async {
    try {
      final profile = await tenant(id);
      final userId = profile.userId;
      if (userId == null) {
        throw StateError('Tenant profile has no linked user id.');
      }
      await _dio.put('${ApiConstants.adminUsers}/$userId/lock');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Contracts ──────────────────────────────────────────────────────────────

  Future<void> archiveTenant(int id) async {
    try {
      await _dio.put('${ApiConstants.adminTenants}/$id/archive');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<void> deleteTenant(int id) async {
    try {
      await _dio.delete('${ApiConstants.adminTenants}/$id');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<void> unlockTenantAccount(int userId) async {
    try {
      await _dio.put('${ApiConstants.adminUsers}/$userId/unlock');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<void> lockTenantAccount(int userId) async {
    try {
      await _dio.put('${ApiConstants.adminUsers}/$userId/lock');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<void> updateTenantUsername(int userId, String username) async {
    try {
      await _dio.put(
        '${ApiConstants.adminUsers}/$userId/username',
        data: {'username': username},
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<void> resetTenantPassword(int userId, String newPassword) async {
    try {
      await _dio.put(
        '${ApiConstants.adminUsers}/$userId/reset-password',
        data: {'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/contracts
  Future<PageResponse<RentalContract>> contracts({
    int page = 0,
    int size = 20,
    String? status,
    String? sort,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminContracts,
        queryParameters: {
          'page': page,
          'size': size,
          if (status != null) 'status': status,
          if (sort != null) 'sort': sort,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<RentalContract>.fromJson(
        apiResponse.data!,
        (json) => RentalContract.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/tenants/{id}/contracts
  Future<PageResponse<RentalContract>> tenantContracts(
    int tenantId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.adminTenants}/$tenantId/contracts',
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<RentalContract>.fromJson(
        apiResponse.data!,
        (json) => RentalContract.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/contracts/{id}
  Future<RentalContract> contract(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminContracts}/$id');
      final apiResponse = ApiResponse<RentalContract>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RentalContract.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/contracts
  Future<RentalContract> createContract(ContractCreateRequest req) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminContracts,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<RentalContract>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RentalContract.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/contracts/{id}/terminate
  Future<RentalContract> terminateContract(
    int id,
    ContractTerminateRequest req,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminContracts}/$id/terminate',
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<RentalContract>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RentalContract.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Meter Readings ─────────────────────────────────────────────────────────

  // GET /admin/meter-readings
  Future<PageResponse<MeterReading>> meterReadings({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminMeterReadings,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<MeterReading>.fromJson(
        apiResponse.data!,
        (json) => MeterReading.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/meter-readings
  Future<MeterReading> createMeterReading(MeterReadingRequest req) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminMeterReadings,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<MeterReading>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MeterReading.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/meter-readings/{id}
  Future<MeterReading> updateMeterReading(
    int id,
    MeterReadingRequest req,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminMeterReadings}/$id',
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<MeterReading>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MeterReading.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/meter-readings/{id}/cancel
  Future<MeterReading> cancelMeterReading(int id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminMeterReadings}/$id/cancel',
      );
      final apiResponse = ApiResponse<MeterReading>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MeterReading.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/rooms/{roomId}/meter-readings/latest
  Future<MeterReading?> latestRoomReading(int roomId, {int? serviceId}) async {
    try {
      final response = await _dio.get(
        '/admin/rooms/$roomId/meter-readings/latest',
        queryParameters: {if (serviceId != null) 'serviceId': serviceId},
      );
      if (response.data == null ||
          (response.data as Map<String, dynamic>)['data'] == null) {
        return null;
      }
      final apiResponse = ApiResponse<MeterReading>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MeterReading.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw e.error ?? e;
    }
  }

  // ─── Invoices ───────────────────────────────────────────────────────────────

  // GET /admin/invoices
  Future<PageResponse<Invoice>> invoices({
    int page = 0,
    int size = 20,
    String? status,
    int? month,
    int? year,
    int? tenantId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminInvoices,
        queryParameters: {
          'page': page,
          'size': size,
          if (status != null) 'status': status,
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          if (tenantId != null) 'tenantId': tenantId,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Invoice>.fromJson(
        apiResponse.data!,
        (json) => Invoice.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/invoices/{id}
  Future<InvoiceDetail> invoiceDetail(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminInvoices}/$id');
      final apiResponse = ApiResponse<InvoiceDetail>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => InvoiceDetail.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/invoices/generate-draft
  Future<Invoice> generateDraft(GenerateInvoiceRequest req) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminInvoicesGenerateDraft,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<Invoice>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Invoice.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/invoices/generate-monthly
  Future<List<Invoice>> generateMonthly(
    GenerateMonthlyInvoicesRequest req,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminInvoicesGenerateMonthly,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      return (apiResponse.data!)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/invoices/{id}/issue
  Future<Invoice> issueInvoice(int id, InvoiceIssueRequest req) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminInvoices}/$id/issue',
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<Invoice>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Invoice.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/invoices/{id}/cancel
  Future<Invoice> cancelInvoice(int id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminInvoices}/$id/cancel',
      );
      final apiResponse = ApiResponse<Invoice>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Invoice.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Payments ───────────────────────────────────────────────────────────────

  // GET /admin/payments
  Future<PageResponse<Payment>> payments({
    int page = 0,
    int size = 20,
    int? invoiceId,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminPayments,
        queryParameters: {
          'page': page,
          'size': size,
          if (invoiceId != null) 'invoiceId': invoiceId,
          if (status != null) 'status': status,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Payment>.fromJson(
        apiResponse.data!,
        (json) => Payment.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/invoices/{invoiceId}/payments
  Future<Payment> recordPayment(int invoiceId, PaymentCreateRequest req) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.adminInvoices}/$invoiceId/payments',
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<Payment>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Payment.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/payments/{id}/cancel
  Future<Payment> cancelPayment(int id, String reason) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminPayments}/$id/cancel',
        data: PaymentCancelRequest(reason: reason).toJson(),
      );
      final apiResponse = ApiResponse<Payment>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Payment.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Debts ──────────────────────────────────────────────────────────────────

  // GET /admin/debts
  Future<PageResponse<Invoice>> debts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminDebts,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Invoice>.fromJson(
        apiResponse.data!,
        (json) => Invoice.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Maintenance Requests ────────────────────────────────────────────────────

  // GET /admin/maintenance-requests
  Future<PageResponse<MaintenanceRequest>> maintenanceRequests({
    int page = 0,
    int size = 20,
    String? status,
    int? tenantId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminMaintenanceRequests,
        queryParameters: {
          'page': page,
          'size': size,
          if (status != null) 'status': status,
          if (tenantId != null) 'tenantId': tenantId,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<MaintenanceRequest>.fromJson(
        apiResponse.data!,
        (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/maintenance-requests/{id}/updates
  Future<PageResponse<MaintenanceUpdate>> maintenanceUpdates(
    int id, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.adminMaintenanceRequests}/$id/updates',
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<MaintenanceUpdate>.fromJson(
        apiResponse.data!,
        (json) => MaintenanceUpdate.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /admin/maintenance-requests/{id}
  Future<MaintenanceRequest> maintenanceRequest(int id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.adminMaintenanceRequests}/$id',
      );
      final apiResponse = ApiResponse<MaintenanceRequest>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/maintenance-requests/{id}/receive
  Future<MaintenanceRequest> receiveRequest(int id, String notes) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminMaintenanceRequests}/$id/receive',
        data: {
          'content': notes.trim().isEmpty
              ? 'Đã tiếp nhận yêu cầu'
              : notes.trim(),
        },
      );
      final apiResponse = ApiResponse<MaintenanceRequest>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/maintenance-requests/{id}/progress
  Future<MaintenanceRequest> progressRequest(int id, String notes) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminMaintenanceRequests}/$id/in-progress',
        data: {
          'content': notes.trim().isEmpty ? 'Đang xử lý yêu cầu' : notes.trim(),
        },
      );
      final apiResponse = ApiResponse<MaintenanceRequest>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/maintenance-requests/{id}/resolve
  Future<MaintenanceRequest> resolveRequest(int id, String notes) async {
    final content = notes.trim().isEmpty ? 'Đã xử lý yêu cầu' : notes.trim();
    try {
      final response = await _dio.put(
        '${ApiConstants.adminMaintenanceRequests}/$id/resolve',
        data: {'content': content, 'resolutionSummary': content},
      );
      final apiResponse = ApiResponse<MaintenanceRequest>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/maintenance-requests/{id}/reject
  Future<MaintenanceRequest> rejectRequest(int id, String notes) async {
    final content = notes.trim().isEmpty ? 'Yêu cầu bị từ chối' : notes.trim();
    try {
      final response = await _dio.put(
        '${ApiConstants.adminMaintenanceRequests}/$id/reject',
        data: {'content': content, 'rejectedReason': content},
      );
      final apiResponse = ApiResponse<MaintenanceRequest>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Services ───────────────────────────────────────────────────────────────

  // GET /admin/services
  Future<List<ServiceItem>> services({bool? activeOnly}) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminServices,
        queryParameters: {if (activeOnly != null) 'activeOnly': activeOnly},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      final page = PageResponse<ServiceItem>.fromJson(
        apiResponse.data!,
        (json) => ServiceItem.fromJson(json),
      );
      return page.content
          .where(
            (service) => activeOnly == true ? service.active == true : true,
          )
          .toList();
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/services
  Future<ServiceItem> createService(ServiceRequest req) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminServices,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<ServiceItem>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServiceItem.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/services/{id}
  Future<ServiceItem> updateService(int id, ServiceRequest req) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminServices}/$id',
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<ServiceItem>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServiceItem.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /admin/services/{id}/activate|deactivate
  Future<ServiceItem> setServiceActive(int id, bool active) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.adminServices}/$id/${active ? 'activate' : 'deactivate'}',
      );
      final apiResponse = ApiResponse<ServiceItem>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServiceItem.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/service-prices
  Future<ServicePrice> addServicePrice(ServicePriceRequest req) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminServicePrices,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<ServicePrice>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServicePrice.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ─── Notifications ──────────────────────────────────────────────────────────

  // GET /admin/notifications
  Future<PageResponse<AppNotification>> notifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminNotifications,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<AppNotification>.fromJson(
        apiResponse.data!,
        (json) => AppNotification.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /admin/notifications/broadcast
  Future<void> broadcastNotification(NotificationBroadcastRequest req) async {
    try {
      await _dio.post(
        ApiConstants.adminNotificationsBroadcast,
        data: req.toJson(),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }
}
