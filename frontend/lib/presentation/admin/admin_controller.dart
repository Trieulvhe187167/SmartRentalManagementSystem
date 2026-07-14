import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_client.dart';
import '../../data/models/admin_models.dart';
import '../../data/models/contract_models.dart';
import '../../data/models/invoice_models.dart';
import '../../data/models/maintenance_models.dart';
import '../../data/models/room_models.dart';
import '../../data/models/tenant_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../tenant/tenant_controller.dart'; // import PaginatedState

// ─── Dashboard Providers ─────────────────────────────────
final adminDashboardProvider = FutureProvider<AdminDashboardResponse>((
  ref,
) async {
  return AdminRepository.instance.dashboardSummary();
});

final adminRoomStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return AdminRepository.instance.roomStats();
});

final adminRevenueSummaryProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  return AdminRepository.instance.revenueSummary();
});

final adminExpiringContractsProvider = FutureProvider<List<RentalContract>>((
  ref,
) async {
  return AdminRepository.instance.expiringContracts();
});

final adminNearestActiveContractsProvider =
    FutureProvider<List<RentalContract>>((ref) async {
      final page = await AdminRepository.instance.contracts(
        page: 0,
        size: 3,
        status: 'ACTIVE',
        sort: 'endDate,asc',
      );
      return page.content;
    });

// ─── Admin Rooms Provider ────────────────────────────────
class AdminRoomsNotifier extends StateNotifier<PaginatedState<Room>> {
  AdminRoomsNotifier() : super(const PaginatedState()) {
    fetchRooms();
  }

  String _searchQuery = '';
  String? _statusFilter;

  void updateSearch(String query) {
    _searchQuery = query;
    fetchRooms(refresh: true);
  }

  void updateStatus(String? status) {
    _statusFilter = status == 'ALL' ? null : status;
    fetchRooms(refresh: true);
  }

  Future<void> fetchRooms({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(
        isLoadingMore: state.currentPage > 0,
        isLoading: state.currentPage == 0,
      );
    }

    try {
      final pageResponse = await AdminRepository.instance.rooms(
        page: state.currentPage,
        size: 20,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter,
      );
      state = state.copyWith(
        items: refresh
            ? pageResponse.content
            : [...state.items, ...pageResponse.content],
        isLoading: false,
        isLoadingMore: false,
        hasMore: pageResponse.hasNextPage,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> createRoom(RoomRequest req) async {
    try {
      await AdminRepository.instance.createRoom(req);
      fetchRooms(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminRoomsProvider =
    StateNotifierProvider<AdminRoomsNotifier, PaginatedState<Room>>((ref) {
      return AdminRoomsNotifier();
    });

// ─── Admin Tenants Provider ──────────────────────────────
class AdminTenantsNotifier
    extends StateNotifier<PaginatedState<TenantProfile>> {
  AdminTenantsNotifier() : super(const PaginatedState()) {
    fetchTenants();
  }

  String _searchQuery = '';

  void updateSearch(String query) {
    _searchQuery = query;
    fetchTenants(refresh: true);
  }

  Future<void> fetchTenants({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(
        isLoadingMore: state.currentPage > 0,
        isLoading: state.currentPage == 0,
      );
    }

    try {
      final pageResponse = await AdminRepository.instance.tenants(
        page: state.currentPage,
        size: 20,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
      );
      state = state.copyWith(
        items: refresh
            ? pageResponse.content
            : [...state.items, ...pageResponse.content],
        isLoading: false,
        isLoadingMore: false,
        hasMore: pageResponse.hasNextPage,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> createTenant(TenantRequest req) async {
    try {
      await AdminRepository.instance.createTenant(req);
      fetchTenants(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTenant(int id, TenantRequest req) async {
    try {
      await AdminRepository.instance.updateTenant(id, req);
      fetchTenants(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> archiveTenant(int id) async {
    try {
      await AdminRepository.instance.archiveTenant(id);
      fetchTenants(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteTenant(int id) async {
    try {
      await AdminRepository.instance.deleteTenant(id);
      fetchTenants(refresh: true);
      return null;
    } on ApiException catch (e) {
      if (e.errorCode == 'TENANT_HAS_HISTORY') {
        return 'Khách đã có hợp đồng hoặc hóa đơn, hãy lưu trữ thay vì xóa.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> unlockTenantAccount(int userId) async {
    try {
      await AdminRepository.instance.unlockTenantAccount(userId);
      fetchTenants(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> lockTenantAccount(int userId) async {
    try {
      await AdminRepository.instance.lockTenantAccount(userId);
      fetchTenants(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTenantUsername(int userId, String username) async {
    try {
      await AdminRepository.instance.updateTenantUsername(userId, username);
      fetchTenants(refresh: true);
      return null;
    } on ApiException catch (e) {
      if (e.errorCode == 'USER_USERNAME_EXISTS') {
        return 'Tên đăng nhập đã tồn tại.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetTenantPassword(int userId, String newPassword) async {
    try {
      await AdminRepository.instance.resetTenantPassword(userId, newPassword);
      fetchTenants(refresh: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminTenantsProvider =
    StateNotifierProvider<AdminTenantsNotifier, PaginatedState<TenantProfile>>((
      ref,
    ) {
      return AdminTenantsNotifier();
    });

// ─── Admin Contracts Provider ────────────────────────────
class AdminContractsNotifier
    extends StateNotifier<PaginatedState<RentalContract>> {
  AdminContractsNotifier() : super(const PaginatedState()) {
    fetchContracts();
  }

  String? _statusFilter;

  void updateStatus(String? status) {
    _statusFilter = status == 'ALL' ? null : status;
    fetchContracts(refresh: true);
  }

  Future<void> fetchContracts({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(
        isLoadingMore: state.currentPage > 0,
        isLoading: state.currentPage == 0,
      );
    }

    try {
      final pageResponse = await AdminRepository.instance.contracts(
        page: state.currentPage,
        size: 20,
        status: _statusFilter,
      );
      state = state.copyWith(
        items: refresh
            ? pageResponse.content
            : [...state.items, ...pageResponse.content],
        isLoading: false,
        isLoadingMore: false,
        hasMore: pageResponse.hasNextPage,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> createContract(ContractCreateRequest req) async {
    try {
      await AdminRepository.instance.createContract(req);
      fetchContracts(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> terminate(int id, String reason, String date) async {
    try {
      await AdminRepository.instance.terminateContract(
        id,
        ContractTerminateRequest(terminationDate: date, reason: reason),
      );
      fetchContracts(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminContractsProvider =
    StateNotifierProvider<
      AdminContractsNotifier,
      PaginatedState<RentalContract>
    >((ref) {
      return AdminContractsNotifier();
    });

// ─── Admin Invoices Provider ─────────────────────────────
class AdminInvoicesNotifier extends StateNotifier<PaginatedState<Invoice>> {
  AdminInvoicesNotifier() : super(const PaginatedState()) {
    fetchInvoices();
  }

  String? _statusFilter;
  int? _month;
  int? _year;

  void updateFilters(String? status, int? month, int? year) {
    _statusFilter = status == 'ALL' ? null : status;
    _month = month;
    _year = year;
    fetchInvoices(refresh: true);
  }

  Future<void> fetchInvoices({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(
        isLoadingMore: state.currentPage > 0,
        isLoading: state.currentPage == 0,
      );
    }

    try {
      final pageResponse = await AdminRepository.instance.invoices(
        page: state.currentPage,
        size: 20,
        status: _statusFilter,
        month: _month,
        year: _year,
      );
      state = state.copyWith(
        items: refresh
            ? pageResponse.content
            : [...state.items, ...pageResponse.content],
        isLoading: false,
        isLoadingMore: false,
        hasMore: pageResponse.hasNextPage,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> generateMonthly(int month, int year) async {
    try {
      await AdminRepository.instance.generateMonthly(
        GenerateMonthlyInvoicesRequest(billingMonth: month, billingYear: year),
      );
      fetchInvoices(refresh: true);
      return null;
    } on ApiException catch (e) {
      if (e.errorCode == 'METER_READING_NOT_FOUND') {
        return _missingMeterReadingMessage(e.message, month, year);
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> issueInvoice(int id, String dueDate) async {
    try {
      await AdminRepository.instance.issueInvoice(
        id,
        InvoiceIssueRequest(dueDate: dueDate),
      );
      fetchInvoices(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> cancelInvoice(int id) async {
    try {
      await AdminRepository.instance.cancelInvoice(id);
      fetchInvoices(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminInvoicesProvider =
    StateNotifierProvider<AdminInvoicesNotifier, PaginatedState<Invoice>>((
      ref,
    ) {
      return AdminInvoicesNotifier();
    });

String _missingMeterReadingMessage(String message, int month, int year) {
  final match = RegExp(
    r'room ([^,]+), service ([^,]+), period ([^,]+)',
  ).firstMatch(message);
  if (match == null) {
    return 'Thiếu chỉ số điện/nước kỳ $month/$year. Vui lòng nhập chỉ số trước khi tạo hóa đơn.';
  }
  final room = match.group(1);
  final service = match.group(2);
  final period = match.group(3);
  return 'Thiếu chỉ số $service cho phòng $room kỳ $period. Vui lòng nhập chỉ số trước khi tạo hóa đơn.';
}

// ─── Admin Maintenance Provider ──────────────────────────
class AdminMaintenanceNotifier
    extends StateNotifier<PaginatedState<MaintenanceRequest>> {
  AdminMaintenanceNotifier() : super(const PaginatedState()) {
    fetchRequests();
  }

  String? _statusFilter;

  void updateStatus(String? status) {
    _statusFilter = status == 'ALL' ? null : status;
    fetchRequests(refresh: true);
  }

  Future<void> fetchRequests({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(
        isLoadingMore: state.currentPage > 0,
        isLoading: state.currentPage == 0,
      );
    }

    try {
      final pageResponse = await AdminRepository.instance.maintenanceRequests(
        page: state.currentPage,
        size: 20,
        status: _statusFilter,
      );
      state = state.copyWith(
        items: refresh
            ? pageResponse.content
            : [...state.items, ...pageResponse.content],
        isLoading: false,
        isLoadingMore: false,
        hasMore: pageResponse.hasNextPage,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> updateStatusAction(
    int id,
    String action,
    String notes,
  ) async {
    try {
      if (action == 'RECEIVE') {
        await AdminRepository.instance.receiveRequest(id, notes);
      } else if (action == 'PROGRESS') {
        await AdminRepository.instance.progressRequest(id, notes);
      } else if (action == 'RESOLVE') {
        await AdminRepository.instance.resolveRequest(id, notes);
      } else if (action == 'REJECT') {
        await AdminRepository.instance.rejectRequest(id, notes);
      }
      fetchRequests(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminMaintenanceProvider =
    StateNotifierProvider<
      AdminMaintenanceNotifier,
      PaginatedState<MaintenanceRequest>
    >((ref) {
      return AdminMaintenanceNotifier();
    });
