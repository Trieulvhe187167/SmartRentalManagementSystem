import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/router/app_router.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('redirects unauthenticated users to login', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.adminDashboard,
          isLoggedIn: false,
        ),
        AppRoutes.login,
      );
    });

    test('redirects admin away from tenant routes', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.tenantHome,
          isLoggedIn: true,
          role: 'ROLE_ADMIN',
        ),
        AppRoutes.adminDashboard,
      );
    });

    test('redirects tenant away from admin routes', () {
      expect(
        resolveAuthRedirect(
          location: AppRoutes.adminRooms,
          isLoggedIn: true,
          role: 'TENANT',
        ),
        AppRoutes.unauthorized,
      );
    });

    test('allows public and role-compatible routes', () {
      expect(
        resolveAuthRedirect(location: AppRoutes.login, isLoggedIn: false),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          location: AppRoutes.tenantProfile,
          isLoggedIn: true,
          role: 'TENANT',
        ),
        isNull,
      );
    });
  });
}
