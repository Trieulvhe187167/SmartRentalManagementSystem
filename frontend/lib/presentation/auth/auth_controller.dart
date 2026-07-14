import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';

// ─── State ───────────────────────────────────────────────
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserResponse? user;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, UserResponse? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => user?.role == 'ADMIN';
  bool get isTenant => user?.role == 'TENANT';
}

// ─── Repository provider ─────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository.instance,
);

// ─── Controller ──────────────────────────────────────────
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState()) {
    ApiClient.sessionNotifier.addListener(_handleSessionExpired);
  }

  void _handleSessionExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    ApiClient.sessionNotifier.removeListener(_handleSessionExpired);
    super.dispose();
  }

  /// Check token and load user on app start
  Future<AuthCheckResult> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final isLoggedIn = await ApiClient.isLoggedIn();
      if (!isLoggedIn) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return AuthCheckResult.notLoggedIn;
      }
      final user = await _repository.me();
      await ApiClient.saveRole(user.role ?? '');
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return user.role == 'ADMIN'
          ? AuthCheckResult.admin
          : AuthCheckResult.tenant;
    } catch (e) {
      await ApiClient.clearAuth();
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return AuthCheckResult.notLoggedIn;
    }
  }

  /// Login with username/password
  Future<LoginResult> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _repository.login(request);
      await ApiClient.saveToken(response.accessToken);
      await ApiClient.saveRole(response.user?.role ?? '');
      final user = await _repository.me();
      await ApiClient.saveRole(user.role ?? '');
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return LoginResult.success(role: user.role ?? '');
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.message);
      return LoginResult.failure(e.message);
    } catch (e) {
      final msg = 'Đăng nhập thất bại. Vui lòng thử lại.';
      state = state.copyWith(status: AuthStatus.error, error: msg);
      return LoginResult.failure(msg);
    }
  }

  /// Change password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _repository.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      return null; // success
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Đổi mật khẩu thất bại. Vui lòng thử lại.';
    }
  }

  Future<ForgotPasswordResult> forgotPassword(String usernameOrEmail) async {
    try {
      await _repository.forgotPassword(
        ForgotPasswordRequest(usernameOrEmail: usernameOrEmail),
      );
      return ForgotPasswordResult.success();
    } on ApiException catch (e) {
      if (e.errorCode == 'PASSWORD_RESET_ACCOUNT_NOT_FOUND') {
        return ForgotPasswordResult.failure(
          'Không tìm thấy tài khoản hoặc email đã đăng ký.',
        );
      }
      if (e.errorCode == 'PASSWORD_RESET_EMAIL_MISSING') {
        return ForgotPasswordResult.failure(
          'Tài khoản chưa có email để nhận hướng dẫn đặt lại mật khẩu.',
        );
      }
      return ForgotPasswordResult.failure(e.message);
    } catch (e) {
      return ForgotPasswordResult.failure(
        'Không thể tạo yêu cầu đặt lại mật khẩu. Vui lòng thử lại.',
      );
    }
  }

  Future<String?> resetForgottenPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _repository.resetForgottenPassword(
        ResetForgottenPasswordRequest(
          token: token,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Không thể đặt lại mật khẩu. Vui lòng thử lại.';
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    await ApiClient.clearAuth();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ─── Auth controller provider ─────────────────────────────
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

// ─── Result types ────────────────────────────────────────
enum AuthCheckResult { notLoggedIn, admin, tenant }

class LoginResult {
  final bool success;
  final String? error;
  final String? role;

  const LoginResult._({required this.success, this.error, this.role});

  factory LoginResult.success({required String role}) =>
      LoginResult._(success: true, role: role);

  factory LoginResult.failure(String error) =>
      LoginResult._(success: false, error: error);

  bool get isAdmin => role == 'ADMIN';
  bool get isTenant => role == 'TENANT';
}

class ForgotPasswordResult {
  final bool success;
  final String? error;

  const ForgotPasswordResult._({required this.success, this.error});

  factory ForgotPasswordResult.success() =>
      const ForgotPasswordResult._(success: true);

  factory ForgotPasswordResult.failure(String error) =>
      ForgotPasswordResult._(success: false, error: error);
}
