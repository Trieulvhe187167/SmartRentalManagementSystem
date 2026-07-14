import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/auth_repository.dart';

import '../../data/models/room_models.dart';

// ─── Screen imports ───────────────────────────────────────
import '../../presentation/auth/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/change_password_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/auth/reset_password_screen.dart';
import '../../presentation/tenant/home_screen.dart';
import '../../presentation/tenant/invoice_detail_screen.dart';
import '../../presentation/tenant/maintenance_screen.dart';
import '../../presentation/tenant/notifications_screen.dart';
import '../../presentation/tenant/profile_screen.dart';
import '../../presentation/admin/admin_dashboard_screen.dart';
import '../../presentation/admin/room_management_screen.dart';
import '../../presentation/admin/room_detail_screen.dart';
import '../../presentation/admin/tenant_management_screen.dart';
import '../../presentation/admin/contract_management_screen.dart';
import '../../presentation/admin/create_contract_screen.dart';
import '../../presentation/admin/invoice_management_screen.dart';
import '../../presentation/admin/meter_reading_screen.dart';
import '../../presentation/admin/revenue_report_screen.dart';
import '../../presentation/admin/maintenance_management_screen.dart';
import '../../presentation/admin/room_form_screen.dart';
import '../../presentation/admin/tenant_detail_screen.dart';
import '../../presentation/admin/payment_recording_screen.dart';
import '../../presentation/admin/maintenance_detail_screen.dart';
import '../../presentation/admin/service_management_screen.dart';
import '../../presentation/shared/unauthorized_screen.dart';
import '../../presentation/shared/network_error_screen.dart';

// ─── Route names ─────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const unauthorized = '/unauthorized';
  static const networkError = '/network-error';

  // Tenant
  static const tenantHome = '/tenant/home';
  static const tenantInvoiceDetail = '/tenant/invoices/:id';
  static const tenantMaintenance = '/tenant/maintenance';
  static const tenantNotifications = '/tenant/notifications';
  static const tenantProfile = '/tenant/profile';

  // Admin
  static const adminDashboard = '/admin/dashboard';
  static const adminRooms = '/admin/rooms';
  static const adminRoomDetail = '/admin/rooms/:id';
  static const adminTenants = '/admin/tenants';
  static const adminContracts = '/admin/contracts';
  static const adminCreateContract = '/admin/contracts/create';
  static const adminInvoices = '/admin/invoices';
  static const adminMeterReadings = '/admin/meter-readings';
  static const adminRevenue = '/admin/revenue';
  static const adminMaintenance = '/admin/maintenance';
  // Keep this outside /admin/rooms/:id so "form" is never parsed as a room id.
  static const adminRoomForm = '/admin/room-form';
  static const adminTenantDetail = '/admin/tenants/:id';
  static const adminPaymentRecording = '/admin/payments/record';
  static const adminMaintenanceDetail = '/admin/maintenance/:id';
  static const adminServices = '/admin/services';

  static String invoiceDetail(int id) => '/tenant/invoices/$id';
  static String roomDetail(int id) => '/admin/rooms/$id';
  static String tenantDetail(int id) => '/admin/tenants/$id';
  static String maintenanceDetail(int id) => '/admin/maintenance/$id';
}

// ─── Router provider ─────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: _guard,
    routes: _routes,
    errorBuilder: (context, state) => const NetworkErrorScreen(),
  );
});

/// Auth guard: redirect based on login state and role
Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final isLoggedIn = await ApiClient.isLoggedIn();
  var role = _normalizeRole(await ApiClient.getRole());
  final location = state.matchedLocation;

  // Allow public routes
  if (location == AppRoutes.splash ||
      location == AppRoutes.login ||
      location == AppRoutes.forgotPassword ||
      location == AppRoutes.resetPassword ||
      location == AppRoutes.unauthorized ||
      location == AppRoutes.networkError) {
    return null;
  }

  // Not logged in → login
  if (!isLoggedIn) {
    return AppRoutes.login;
  }

  if (role == null || role.isEmpty) {
    try {
      final user = await AuthRepository.instance.me();
      role = _normalizeRole(user.role);
      await ApiClient.saveRole(role ?? '');
    } catch (_) {
      await ApiClient.clearAuth();
      return AppRoutes.login;
    }
  }

  // Admin trying to access tenant routes
  if (role == 'ADMIN' && location.startsWith('/tenant')) {
    return AppRoutes.adminDashboard;
  }

  // Tenant trying to access admin routes
  if (role == 'TENANT' && location.startsWith('/admin')) {
    return AppRoutes.unauthorized;
  }

  return null;
}

String? _normalizeRole(String? role) {
  if (role == null || role.isEmpty) return role;
  return role.replaceFirst('ROLE_', '').toUpperCase();
}

final _routes = <RouteBase>[
  // ─── Shared / Auth ─────────────────────────────────────
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AppRoutes.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.changePassword,
    builder: (context, state) => const ChangePasswordScreen(),
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: AppRoutes.resetPassword,
    builder: (context, state) {
      final token = state.extra is String
          ? state.extra as String
          : state.uri.queryParameters['token'];
      final username = state.uri.queryParameters['username'];
      return ResetPasswordScreen(initialToken: token, username: username);
    },
  ),
  GoRoute(
    path: AppRoutes.unauthorized,
    builder: (context, state) => const UnauthorizedScreen(),
  ),
  GoRoute(
    path: AppRoutes.networkError,
    builder: (context, state) => const NetworkErrorScreen(),
  ),

  // ─── Tenant ────────────────────────────────────────────
  ShellRoute(
    builder: (context, state, child) => TenantShell(child: child),
    routes: [
      GoRoute(
        path: AppRoutes.tenantHome,
        builder: (context, state) => const TenantHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.tenantMaintenance,
        builder: (context, state) => const TenantMaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.tenantNotifications,
        builder: (context, state) => const TenantNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tenantProfile,
        builder: (context, state) => const TenantProfileScreen(),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.tenantInvoiceDetail,
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return TenantInvoiceDetailScreen(invoiceId: id);
    },
  ),

  // ─── Admin ─────────────────────────────────────────────
  ShellRoute(
    builder: (context, state, child) => AdminShell(child: child),
    routes: [
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRooms,
        builder: (context, state) => const AdminRoomManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminTenants,
        builder: (context, state) => const AdminTenantManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminContracts,
        builder: (context, state) => const AdminContractManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminInvoices,
        builder: (context, state) => const AdminInvoiceManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMeterReadings,
        builder: (context, state) => const AdminMeterReadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRevenue,
        builder: (context, state) => const AdminRevenueReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMaintenance,
        builder: (context, state) => const AdminMaintenanceManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminServices,
        builder: (context, state) => const AdminServiceManagementScreen(),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.adminRoomDetail,
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return AdminRoomDetailScreen(roomId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.adminRoomForm,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final roomId = extra?['roomId'] as int?;
      final room = extra?['room'] as Room?;
      return AdminRoomFormScreen(roomId: roomId, existingRoom: room);
    },
  ),
  GoRoute(
    path: AppRoutes.adminTenantDetail,
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return AdminTenantDetailScreen(tenantId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.adminPaymentRecording,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return AdminPaymentRecordingScreen(
        invoiceId: extra['invoiceId'] as int,
        remainingAmount: extra['remainingAmount'] as double,
        tenantName: extra['tenantName'] as String?,
        roomNumber: extra['roomNumber'] as String?,
        billingMonth: extra['billingMonth'] as int?,
        billingYear: extra['billingYear'] as int?,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.adminMaintenanceDetail,
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return AdminMaintenanceDetailScreen(requestId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.adminCreateContract,
    builder: (context, state) => const AdminCreateContractScreen(),
  ),
];

// ─── Tenant Shell (bottom nav) ───────────────────────────
class TenantShell extends StatelessWidget {
  final Widget child;
  const TenantShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location == AppRoutes.tenantHome) currentIndex = 0;
    if (location == AppRoutes.tenantMaintenance) currentIndex = 1;
    if (location == AppRoutes.tenantNotifications) currentIndex = 2;
    if (location == AppRoutes.tenantProfile) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.tenantHome);
            case 1:
              context.go(AppRoutes.tenantMaintenance);
            case 2:
              context.go(AppRoutes.tenantNotifications);
            case 3:
              context.go(AppRoutes.tenantProfile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Sửa chữa',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

// ─── Admin Shell (bottom nav) ────────────────────────────
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location == AppRoutes.adminDashboard) currentIndex = 0;
    if (location == AppRoutes.adminRooms ||
        location == AppRoutes.adminTenants ||
        location == AppRoutes.adminContracts)
      currentIndex = 1;
    if (location == AppRoutes.adminInvoices ||
        location == AppRoutes.adminMeterReadings)
      currentIndex = 2;
    if (location == AppRoutes.adminRevenue ||
        location == AppRoutes.adminMaintenance)
      currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.adminDashboard);
            case 1:
              context.go(AppRoutes.adminRooms);
            case 2:
              context.go(AppRoutes.adminInvoices);
            case 3:
              context.go(AppRoutes.adminRevenue);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Quản lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
        ],
      ),
    );
  }
}
