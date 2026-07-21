import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tenant_models.dart';
import '../../data/models/invoice_models.dart';
import '../../data/models/maintenance_models.dart';
import '../../data/models/notification_models.dart';
import '../../data/models/contract_models.dart';
import '../../data/repositories/tenant_repository.dart';
import '../../data/repositories/notification_repository.dart';

// ─── Paginated State Class ───────────────────────────────
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// ─── Tenant Dashboard Provider ───────────────────────────
class TenantDashboardNotifier extends AsyncNotifier<TenantDashboardResponse> {
  @override
  Future<TenantDashboardResponse> build() async {
    return TenantRepository.instance.dashboard();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => TenantRepository.instance.dashboard());
  }
}

final tenantDashboardProvider =
    AsyncNotifierProvider<TenantDashboardNotifier, TenantDashboardResponse>(
  TenantDashboardNotifier.new,
);

// ─── Tenant Contract Provider ────────────────────────────
final tenantContractProvider = FutureProvider.autoDispose<RentalContract?>((
  ref,
) async {
  return TenantRepository.instance.currentContract();
});

// ─── Tenant Invoices Provider ────────────────────────────
class TenantInvoicesNotifier extends StateNotifier<PaginatedState<Invoice>> {
  TenantInvoicesNotifier() : super(const PaginatedState()) {
    fetchInvoices();
  }

  Future<void> fetchInvoices({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(isLoadingMore: state.currentPage > 0, isLoading: state.currentPage == 0);
    }

    try {
      final pageResponse = await TenantRepository.instance.invoices(
        page: state.currentPage,
        size: 20,
      );
      state = state.copyWith(
        items: refresh ? pageResponse.content : [...state.items, ...pageResponse.content],
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
}

final tenantInvoicesProvider =
    StateNotifierProvider<TenantInvoicesNotifier, PaginatedState<Invoice>>((ref) {
  return TenantInvoicesNotifier();
});

// ─── Tenant Maintenance Provider ──────────────────────────
class TenantMaintenanceNotifier extends StateNotifier<PaginatedState<MaintenanceRequest>> {
  TenantMaintenanceNotifier() : super(const PaginatedState()) {
    fetchRequests();
  }

  Future<void> fetchRequests({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(isLoadingMore: state.currentPage > 0, isLoading: state.currentPage == 0);
    }

    try {
      final pageResponse = await TenantRepository.instance.maintenanceRequests(
        page: state.currentPage,
        size: 20,
      );
      state = state.copyWith(
        items: refresh ? pageResponse.content : [...state.items, ...pageResponse.content],
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

  Future<String?> createRequest(String title, String description, String priority, String category) async {
    try {
      final req = MaintenanceRequestCreateRequest(
        title: title,
        description: description,
        priority: priority,
        category: category,
      );
      await TenantRepository.instance.createMaintenanceRequest(req);
      await fetchRequests(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> cancelRequest(int id) async {
    try {
      await TenantRepository.instance.cancelMaintenanceRequest(id);
      fetchRequests(refresh: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final tenantMaintenanceProvider =
    StateNotifierProvider<TenantMaintenanceNotifier, PaginatedState<MaintenanceRequest>>((ref) {
  return TenantMaintenanceNotifier();
});

// ─── Tenant Notifications Provider ────────────────────────
class TenantNotificationsNotifier extends StateNotifier<PaginatedState<AppNotification>> {
  TenantNotificationsNotifier() : super(const PaginatedState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 0, items: []);
    } else {
      state = state.copyWith(isLoadingMore: state.currentPage > 0, isLoading: state.currentPage == 0);
    }

    try {
      final pageResponse = await NotificationRepository.instance.getNotifications(
        page: state.currentPage,
      );
      state = state.copyWith(
        items: refresh ? pageResponse.content : [...state.items, ...pageResponse.content],
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

  Future<void> markRead(int id) async {
    try {
      await NotificationRepository.instance.markAsRead(id);
      // local update
      state = state.copyWith(
        items: state.items.map((n) => n.id == id ? AppNotification(
          id: n.id,
          title: n.title,
          content: n.content,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        ) : n).toList(),
      );
    } catch (_) {}
  }
}

final tenantNotificationsProvider =
    StateNotifierProvider<TenantNotificationsNotifier, PaginatedState<AppNotification>>((ref) {
  return TenantNotificationsNotifier();
});

// ─── Unread Count Provider ──────────────────────────────
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  return NotificationRepository.instance.getUnreadCount();
});
