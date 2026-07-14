/// API Constants for Lumina Resident App
/// Change baseUrl depending on your environment:
///   Android Emulator : http://10.0.2.2:8080/api/v1
///   iOS Simulator    : http://localhost:8080/api/v1
///   Physical device  : `http://<LAN-IP>:8080/api/v1`
///   Production       : https://your-domain.com/api/v1
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  // ─── Auth ────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  // ─── Tenant ──────────────────────────────────────────────
  static const String tenantDashboard = '/tenant/dashboard';
  static const String tenantCurrentRoom = '/tenant/current-room';
  static const String tenantCurrentInvoice = '/tenant/current-invoice';
  static const String tenantCurrentDebt = '/tenant/current-debt';
  static const String tenantInvoices = '/tenant/invoices';
  static const String tenantPayments = '/tenant/payments';
  static const String tenantMeterReadings = '/tenant/meter-readings';
  static const String tenantDebt = '/tenant/debt';
  static const String tenantMaintenance = '/tenant/maintenance-requests';
  static const String tenantNotifications = '/notifications';
  static const String tenantMaintenanceRequests = tenantMaintenance;
  static const String tenantNotificationsUnreadCount =
      '/notifications/unread-count';

  // ─── Admin Dashboard ─────────────────────────────────────
  static const String adminDashboardSummary = '/admin/dashboard/summary';
  static const String adminDashboardRooms = '/admin/dashboard/rooms';
  static const String adminDashboardRevenue = '/admin/dashboard/revenue';
  static const String adminContractsExpiring =
      '/admin/dashboard/contracts-expiring';
  static const String adminOpenMaintenance =
      '/admin/dashboard/open-maintenance';
  static const String adminDashboard = adminDashboardSummary;
  static const String adminRoomStats = adminDashboardRooms;
  static const String adminRevenueSummary = adminDashboardRevenue;
  static const String adminExpiringContracts = adminContractsExpiring;

  // ─── Admin Rooms ─────────────────────────────────────────
  static const String adminRooms = '/admin/rooms';
  static const String adminBuildings = '/admin/buildings';
  static const String adminFloors = '/admin/floors';
  static const String adminTenantAccounts = '/admin/users/tenant-accounts';
  static const String adminUsers = '/admin/users';

  // ─── Admin Tenants ────────────────────────────────────────
  static const String adminTenants = '/admin/tenants';

  // ─── Admin Contracts ──────────────────────────────────────
  static const String adminContracts = '/admin/contracts';

  // ─── Admin Services ───────────────────────────────────────
  static const String adminServices = '/admin/services';
  static const String adminServicePrices = '/admin/service-prices';

  // ─── Admin Meter Readings ────────────────────────────────
  static const String adminMeterReadings = '/admin/meter-readings';

  // ─── Admin Invoices ───────────────────────────────────────
  static const String adminInvoices = '/admin/invoices';
  static const String adminGenerateDraft = '/admin/invoices/generate-draft';
  static const String adminGenerateMonthly = '/admin/invoices/generate-monthly';
  static const String adminInvoicesGenerateDraft = adminGenerateDraft;
  static const String adminInvoicesGenerateMonthly = adminGenerateMonthly;

  // ─── Admin Payments ───────────────────────────────────────
  static const String adminPayments = '/admin/payments';
  static const String adminDebts = '/admin/debts';

  // ─── Admin Maintenance ────────────────────────────────────
  static const String adminMaintenance = '/admin/maintenance-requests';
  static const String adminMaintenanceRequests = adminMaintenance;

  // ─── Admin Notifications ──────────────────────────────────
  static const String adminNotifications = '/notifications';
  static const String adminNotificationsBroadcast =
      '/admin/notifications/general';

  // ─── JWT Storage key ─────────────────────────────────────
  static const String tokenKey = 'access_token';
  static const String userRoleKey = 'user_role';

  // ─── Pagination defaults ─────────────────────────────────
  static const int defaultPageSize = 20;
  static const int defaultPage = 0;
}
