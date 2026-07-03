import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/contract_models.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../auth/auth_controller.dart';
import 'admin_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final roomStatsAsync = ref.watch(adminRoomStatsProvider);
    final revenueAsync = ref.watch(adminRevenueSummaryProvider);
    final expiringContractsAsync = ref.watch(adminExpiringContractsProvider);
    final nearestActiveContractsAsync = ref.watch(adminNearestActiveContractsProvider);
    final userState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard quản lý'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản admin không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true && context.mounted) {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          ref.invalidate(adminRoomStatsProvider);
          ref.invalidate(adminRevenueSummaryProvider);
          ref.invalidate(adminExpiringContractsProvider);
          ref.invalidate(adminNearestActiveContractsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Greeting ──────────────────────────────
              Text(
                'Chào mừng quay trở lại, ${userState.user?.displayName ?? 'Admin'}!',
                style: AppTextStyles.titleLg,
              ),
              Text(
                'Hôm nay: ${DateFormatter.formatFull(DateTime.now())}',
                style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // ─── Stat Cards 2x2 Grid ───────────────────
              dashboardAsync.when(
                data: (data) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                       _buildMiniStatCard(
                        context,
                        'TỔNG SỐ PHÒNG',
                        '${data.totalRooms ?? 0}',
                        Icons.meeting_room_outlined,
                        Theme.of(context).colorScheme.primary,
                      ),
                      _buildMiniStatCard(
                        context,
                        'ĐANG CHO THUÊ',
                        '${data.occupiedRooms ?? 0}',
                        Icons.people_outline,
                        AppColors.success,
                      ),
                      _buildMiniStatCard(
                        context,
                        'DOANH THU THÁNG',
                        CurrencyFormatter.compact(data.currentMonthRevenue),
                        Icons.monetization_on_outlined,
                        Theme.of(context).colorScheme.primaryContainer,
                      ),
                      _buildMiniStatCard(
                        context,
                        'TỔNG TIỀN NỢ',
                        CurrencyFormatter.compact(data.currentMonthDebt),
                        Icons.warning_amber_rounded,
                        AppColors.danger,
                      ),
                    ],
                  );
                },
                loading: () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: List.generate(4, (_) => const LoadingShimmer(height: 80)),
                ),
                error: (_, __) => Text(
                  'Không thể tải thông tin thống kê',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Quick Actions Row ──────────────────────
              Text('Phím tắt quản lý', style: AppTextStyles.titleLg),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShortcutItem(context, 'Quản lý phòng', Icons.meeting_room, AppRoutes.adminRooms),
                    _buildShortcutItem(context, 'Khách thuê', Icons.people, AppRoutes.adminTenants),
                    _buildShortcutItem(context, 'Hợp đồng', Icons.description, AppRoutes.adminContracts),
                    _buildShortcutItem(context, 'Hóa đơn', Icons.receipt_long, AppRoutes.adminInvoices),
                    _buildShortcutItem(context, 'Chỉ số điện nước', Icons.bolt, AppRoutes.adminMeterReadings),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Expiring Contracts ────────────────────
              Text('Hợp đồng sắp hết hạn', style: AppTextStyles.titleLg),
              const SizedBox(height: 12),
              expiringContractsAsync.when(
                data: (contracts) {
                  if (contracts.isEmpty) {
                    return nearestActiveContractsAsync.when(
                      data: (nearestContracts) {
                        if (nearestContracts.isEmpty) {
                          return AppCard(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Không có hợp đồng đang hiệu lực',
                                  style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Không có hợp đồng hết hạn trong 30 ngày. Dưới đây là các hợp đồng gần hết hạn nhất:',
                                style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                            ...nearestContracts.map((c) => _buildContractTile(context, c)),
                          ],
                        );
                      },
                      loading: () => const CardShimmer(height: 80),
                      error: (_, __) => Text(
                        'Không thể tải hợp đồng đang hiệu lực',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    );
                  }
                  return Column(
                    children: contracts.map((c) => _buildContractTile(context, c)).toList(),
                  );
                },
                loading: () => const CardShimmer(height: 80),
                error: (_, __) => Text(
                  'Không thể tải hợp đồng sắp hết hạn',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Pending Maintenance ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yêu cầu sửa chữa chờ xử lý', style: AppTextStyles.titleLg),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.adminMaintenance),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final maintState = ref.watch(adminMaintenanceProvider);
                  if (maintState.isLoading) {
                    return const CardShimmer(height: 80);
                  }
                  final pending = maintState.items
                      .where((item) =>
                          item.status?.toUpperCase() == 'OPEN' ||
                          item.status?.toUpperCase() == 'PENDING' ||
                          item.status?.toUpperCase() == 'RECEIVED')
                      .take(3)
                      .toList();

                  if (pending.isEmpty) {
                    return AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Không có yêu cầu chờ xử lý nào',
                            style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          title: Text(
                            'Phòng ${item.roomNumber} - ${item.title}',
                            style: AppTextStyles.titleSm,
                          ),
                          subtitle: Text(
                            'Gửi ngày: ${DateFormatter.format(DateFormatter.tryParse(item.requestDate))}',
                            style: AppTextStyles.bodySm,
                          ),
                          trailing: PriorityChip(priority: item.priority ?? 'MEDIUM'),
                          onTap: () => context.go(AppRoutes.adminMaintenance),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractTile(BuildContext context, RentalContract contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(
          'Phòng ${contract.roomNumber ?? '—'} - ${contract.tenantName ?? 'Khách thuê'}',
          style: AppTextStyles.titleSm,
        ),
        subtitle: Text(
          'Hết hạn: ${DateFormatter.format(DateFormatter.tryParse(contract.endDate))}',
          style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const StatusChip(status: 'DRAFT', label: 'Gần hết hạn'),
      ),
    );
  }

  Widget _buildMiniStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.titleLg.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primaryContainer, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
