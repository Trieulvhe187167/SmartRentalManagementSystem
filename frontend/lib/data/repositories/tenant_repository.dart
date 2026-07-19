import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../models/tenant_models.dart';
import '../models/invoice_models.dart';
import '../models/payment_models.dart';
import '../models/meter_reading_models.dart';
import '../models/maintenance_models.dart';
import '../models/notification_models.dart';
import '../models/auth_models.dart';
import '../models/contract_models.dart';

class TenantRepository {
  TenantRepository._();
  static final TenantRepository instance = TenantRepository._();

  final _dio = ApiClient.instance.dio;

  Future<UserResponse> updateProfile(TenantProfileUpdateRequest req) async {
    try {
      final response = await _dio.patch(
        ApiConstants.tenantProfile,
        data: req.toJson(),
      );
      final apiResponse = ApiResponse<UserResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<EmailChangeStartResponse> requestEmailChange(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.tenantProfileEmailRequest,
        data: {'email': email},
      );
      final apiResponse = ApiResponse<EmailChangeStartResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            EmailChangeStartResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<UserResponse> verifyEmailChange({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.tenantProfileEmailVerify,
        data: {'email': email, 'code': code},
      );
      final apiResponse = ApiResponse<UserResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/contracts/current
  Future<RentalContract?> currentContract() async {
    try {
      final response = await _dio.get(ApiConstants.tenantCurrentContract);
      final apiResponse = ApiResponse<RentalContract>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RentalContract.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<RentalContract> confirmContract(int contractId) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.tenantContracts}/$contractId/confirm',
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

  Future<RentalContract> rejectContract({
    required int contractId,
    required String reason,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.tenantContracts}/$contractId/reject',
        data: {'reason': reason},
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

  // GET /tenant/dashboard
  Future<TenantDashboardResponse> dashboard() async {
    try {
      final response = await _dio.get(ApiConstants.tenantDashboard);
      final apiResponse = ApiResponse<TenantDashboardResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            TenantDashboardResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/invoices
  Future<PageResponse<Invoice>> invoices({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantInvoices,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      final pageResponse = PageResponse<Invoice>.fromJson(
        apiResponse.data!,
        Invoice.fromJson,
      );
      return pageResponse.copyWith(
        content: pageResponse.content
            .where((invoice) => invoice.isVisibleToTenant)
            .toList(),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/invoices/{id}
  Future<InvoiceDetail> invoiceDetail(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.tenantInvoices}/$id');
      final apiResponse = ApiResponse<InvoiceDetail>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => InvoiceDetail.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/payments
  Future<PageResponse<Payment>> payments({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantPayments,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Payment>.fromJson(
        apiResponse.data!,
        Payment.fromJson,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/meter-readings
  Future<PageResponse<MeterReading>> meterReadings({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantMeterReadings,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<MeterReading>.fromJson(
        apiResponse.data!,
        MeterReading.fromJson,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/debt
  Future<PageResponse<Invoice>> debtInvoices({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantDebt,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<Invoice>.fromJson(
        apiResponse.data!,
        Invoice.fromJson,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/maintenance-requests
  Future<PageResponse<MaintenanceRequest>> maintenanceRequests({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantMaintenanceRequests,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<MaintenanceRequest>.fromJson(
        apiResponse.data!,
        MaintenanceRequest.fromJson,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/maintenance-requests/{id}
  Future<MaintenanceRequest> maintenanceRequest(int id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.tenantMaintenanceRequests}/$id',
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

  // POST /tenant/maintenance-requests
  Future<MaintenanceRequest> createMaintenanceRequest(
    MaintenanceRequestCreateRequest req,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.tenantMaintenanceRequests,
        data: req.toJson(),
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

  // PUT /tenant/maintenance-requests/{id}
  Future<MaintenanceRequest> updateMaintenanceRequest(
    int id,
    MaintenanceRequestUpdateRequest req,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.tenantMaintenanceRequests}/$id',
        data: req.toJson(),
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

  // PUT /tenant/maintenance-requests/{id}/cancel
  Future<MaintenanceRequest> cancelMaintenanceRequest(int id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.tenantMaintenanceRequests}/$id/cancel',
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

  // GET /tenant/notifications
  Future<PageResponse<AppNotification>> notifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantNotifications,
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<AppNotification>.fromJson(
        apiResponse.data!,
        AppNotification.fromJson,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /tenant/notifications/{id}/read
  Future<AppNotification> markRead(int id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.tenantNotifications}/$id/read',
      );
      final apiResponse = ApiResponse<AppNotification>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AppNotification.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }
}
