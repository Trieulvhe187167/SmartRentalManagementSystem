import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../models/notification_models.dart';

/// Lightweight notification repository for tenant-side notification operations.
/// Delegates to the same endpoints as [TenantRepository] but provides a
/// focused interface used by notification-specific providers.
class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _dio = ApiClient.instance.dio;

  // GET /tenant/notifications?page=&size=20
  Future<PageResponse<AppNotification>> getNotifications({int page = 0}) async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantNotifications,
        queryParameters: {'page': page, 'size': 20},
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

  // PUT /tenant/notifications/{id}/read
  Future<void> markAsRead(int id) async {
    try {
      await _dio.put('${ApiConstants.tenantNotifications}/$id/read');
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /tenant/notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(
        ApiConstants.tenantNotificationsUnreadCount,
      );
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
      final data = apiResponse.data;
      if (data is int) return data;
      if (data is Map<String, dynamic>) {
        final value = data['count'] ?? data['unreadCount'] ?? 0;
        return (value as num).toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }
}
