import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';

class AuthSessionNotifier extends ChangeNotifier {
  void sessionExpired() => notifyListeners();
}

/// Custom exception to carry structured error from server
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final List<String> details;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.details = const [],
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isValidationError => statusCode == 400;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

/// Singleton Dio client with JWT interceptor and error handling
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final AuthSessionNotifier sessionNotifier = AuthSessionNotifier();

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(_storage));
    dio.interceptors.add(_ErrorInterceptor());

    // Optional: log in debug mode
    // dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    // ));

    return dio;
  }

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConstants.tokenKey, value: token);
  }

  /// Save user role
  static Future<void> saveRole(String role) async {
    await _storage.write(key: ApiConstants.userRoleKey, value: role);
  }

  /// Read JWT token
  static Future<String?> getToken() async {
    return _storage.read(key: ApiConstants.tokenKey);
  }

  /// Read user role
  static Future<String?> getRole() async {
    return _storage.read(key: ApiConstants.userRoleKey);
  }

  /// Clear all auth data
  static Future<void> clearAuth() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userRoleKey);
  }

  static Future<void> expireSession() async {
    await clearAuth();
    sessionNotifier.sessionExpired();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// Interceptor: automatically attach JWT Bearer token to every request
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: ApiConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If 401 → clear token (don't retry, let router redirect to login)
    if (err.response?.statusCode == 401) {
      await ApiClient.expireSession();
    }
    super.onError(err, handler);
  }
}

/// Interceptor: convert Dio errors → typed ApiException or NetworkException
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Exception exception;

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      exception = const NetworkException(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      );
    } else if (err.response != null) {
      final status = err.response!.statusCode ?? 0;
      final body = err.response!.data;

      String message = _extractMessage(body, status);
      String? errorCode;
      List<String> details = const [];
      Map<String, dynamic>? errors;

      if (body is Map<String, dynamic>) {
        errorCode = body['errorCode']?.toString();
        final rawDetails = body['details'];
        if (rawDetails is List) {
          details = rawDetails.map((item) => item.toString()).toList();
        }
        if (body['errors'] != null) {
          errors = body['errors'] as Map<String, dynamic>?;
        }
      }

      exception = ApiException(
        statusCode: status,
        message: message,
        errorCode: errorCode,
        details: details,
        errors: errors,
      );
    } else {
      exception = const NetworkException('Đã có lỗi xảy ra. Vui lòng thử lại.');
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }

  String _extractMessage(dynamic body, int status) {
    if (body is Map<String, dynamic>) {
      if (body['message'] != null) return body['message'].toString();
      if (body['error'] != null) return body['error'].toString();
    }
    return switch (status) {
      400 => 'Dữ liệu không hợp lệ.',
      401 => 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy dữ liệu.',
      409 => 'Dữ liệu đã tồn tại.',
      422 => 'Dữ liệu không hợp lệ.',
      500 => 'Lỗi máy chủ. Vui lòng thử lại sau.',
      503 => 'Dịch vụ tạm thời không khả dụng.',
      _ => 'Đã có lỗi xảy ra (HTTP $status).',
    };
  }
}
