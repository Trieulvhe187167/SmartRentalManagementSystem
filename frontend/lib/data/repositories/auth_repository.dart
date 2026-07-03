import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _dio = ApiClient.instance.dio;

  // POST /auth/login
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<LoginResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // GET /auth/me
  Future<UserResponse> me() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      final apiResponse = ApiResponse<UserResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /auth/forgot-password
  Future<ForgotPasswordResponse> forgotPassword(
      ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<ForgotPasswordResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            ForgotPasswordResponse.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data ?? const ForgotPasswordResponse();
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /auth/reset-password
  Future<void> resetForgottenPassword(
      ResetForgottenPasswordRequest request) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // PUT /auth/change-password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _dio.put(
        ApiConstants.changePassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // POST /auth/logout
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }
}
