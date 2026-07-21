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
import '../../data/models/maintenance_models.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../auth/auth_controller.dart';
import '../tenant/tenant_controller.dart';
import 'admin_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final expiringContractsAsync = ref.watch(adminExpiringContractsProvider);
    final userState = ref.watch(authControllerProvider);
    final maintState = ref.watch(adminMaintenanceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('RoomManager'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          ref.invalidate(adminExpiringContractsProvider);
          ref.invalidate(adminMaintenanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Welcome Header ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng quay trở lại,',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          userState.user?.displayName ?? 'Admin Quản lý',
                          style: AppTextStyles.headlineSm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormatter.format(DateTime.now()),
                    style: AppTextStyles.labelMd.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Quick Actions (Phím tắt quản lý) ─────────
              Text('Phím tắt quản lý', style: AppTextStyles.titleLg),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.meeting_room_outlined,
                    label: 'Quản lý phòng',
                    color: Theme.of(context).colorScheme.primary,
                    route: AppRoutes.adminRooms,
                  ),
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.people_outline,
                    label: 'Khách thuê',
                    color: AppColors.success,
                    route: AppRoutes.adminTenants,
                  ),
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.bolt,
                    label: 'Nhập điện nước',
                    color: AppColors.warning,
                    route: AppRoutes.adminMeterReadings,
                  ),
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Tạo hóa đơn',
                    color: AppColors.danger,
                    route: AppRoutes.adminInvoices,
                  ),
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.layers,
                    label: 'Dịch vụ',
                    color: const Color(0xFF7C3AED),
                    route: AppRoutes.adminServices,
                  ),
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.description_outlined,
                    label: 'Hợp đồng',
                    color: const Color(0xFF0891B2),
                    route: AppRoutes.adminContracts,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ─── Overview & Revenue ─────────────────────
              dashboardAsync.when(
                data: (data) {
                  final totalRevenue = data.monthlyRevenue;
                  final paidAmount = data.monthlyCollectedAmount;
                  final debtAmount = data.monthlyDebtAmount;
                  final paidRatio = totalRevenue > 0
                      ? paidAmount / totalRevenue
                      : 0.0;
                  final debtRatio = totalRevenue > 0
                      ? debtAmount / totalRevenue
                      : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Cards (Tổng quan tòa nhà)
                      Text('Tổng quan tòa nhà', style: AppTextStyles.titleLg),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _buildOverviewTile(
                            context,
                            'Tổng phòng',
                            '${data.totalRooms}',
                            Icons.apartment,
                            Theme.of(context).colorScheme.primary,
                            const Color(0xFFEFF4FF),
                          ),
                          _buildOverviewTile(
                            context,
                            'Đang thuê',
                            '${data.occupiedRooms}',
                            Icons.check_circle_outline,
                            AppColors.success,
                            const Color(0xFFE8FBF3),
                          ),
                          _buildOverviewTile(
                            context,
                            'Phòng trống',
                            '${data.availableRooms}',
                            Icons.meeting_room,
                            Theme.of(context).colorScheme.tertiary,
                            const Color(0xFFFFF8E1),
                          ),
                          _buildOverviewTile(
                            context,
                            'Đang sửa',
                            '${data.maintenanceRooms}',
                            Icons.build_outlined,
                            AppColors.danger,
                            const Color(0xFFFFDAD6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Revenue Card (Doanh thu tháng này)
                      Text('Doanh thu tháng này', style: AppTextStyles.titleLg),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng dự kiến thu',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalRevenue),
                              style: AppTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Progress 1: Đã thu
                            _buildProgressRow(
                              context: context,
                              label: 'Đã thu',
                              amount: paidAmount,
                              ratio: paidRatio,
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 16),

                            // Progress 2: Còn nợ
                            _buildProgressRow(
                              context: context,
                              label: 'Còn nợ',
                              amount: debtAmount,
                              ratio: debtRatio,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(height: 20),

                            // View detail button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    context.go(AppRoutes.adminInvoices),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const Text('Xem chi tiết hóa đơn'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Chỉ số cần chú ý', style: AppTextStyles.titleLg),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _buildAttentionTile(
                            context: context,
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Tổng công nợ',
                            value: CurrencyFormatter.format(data.totalDebt),
                            color: AppColors.danger,
                            onTap: () => context.go(AppRoutes.adminInvoices),
                          ),
                          _buildAttentionTile(
                            context: context,
                            icon: Icons.event_busy_outlined,
                            label: 'Hợp đồng sắp hết hạn',
                            value: '${data.expiringContractsCount}',
                            color: AppColors.warning,
                            onTap: () => context.go(AppRoutes.adminContracts),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Column(
                  children: [
                    CardShimmer(height: 160),
                    SizedBox(height: 24),
                    CardShimmer(height: 220),
                  ],
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Lỗi tải dữ liệu tổng quan: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Unified Tasks (Công việc cần xử lý) ──────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Công việc cần xử lý', style: AppTextStyles.titleLg),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.adminMaintenance),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildUnifiedTasksList(
                context,
                maintState,
                expiringContractsAsync,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return AppCard(
      onTap: () => context.go(route),
      padding: EdgeInsets.zero,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTextStyles.titleSm.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgLight,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : bgLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                label,
                style: AppTextStyles.bodySm.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required BuildContext context,
    required String label,
    required double amount,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              CurrencyFormatter.format(amount),
              style: AppTextStyles.titleSm.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.titleLg.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedTasksList(
    BuildContext context,
    PaginatedState<MaintenanceRequest> maintState,
    AsyncValue<List<RentalContract>> expiringContractsAsync,
  ) {
    if (maintState.isLoading || expiringContractsAsync.isLoading) {
      return const CardShimmer(height: 120);
    }

    final List<Widget> taskTiles = [];

    // 1. Thêm các yêu cầu sửa chữa chờ xử lý (OPEN, RECEIVED)
    final pendingMaint = maintState.items
        .where(
          (m) =>
              m.status?.toUpperCase() == 'OPEN' ||
              m.status?.toUpperCase() == 'RECEIVED' ||
              m.status?.toUpperCase() == 'IN_PROGRESS',
        )
        .take(3)
        .toList();

    for (final m in pendingMaint) {
      taskTiles.add(
        _buildTaskItem(
          context: context,
          icon: Icons.build_outlined,
          iconBg: AppColors.danger.withValues(alpha: 0.1),
          iconColor: AppColors.danger,
          type: 'Sửa chữa',
          room: 'P.${m.roomNumber ?? '—'}',
          detail: m.title ?? 'Yêu cầu sửa chữa thiết bị',
          statusWidget: PriorityChip(priority: m.priority ?? 'MEDIUM'),
          onTap: () {
            if (m.id != null) {
              context.push(
                AppRoutes.adminMaintenanceDetail.replaceAll(
                  ':id',
                  m.id!.toString(),
                ),
              );
            }
          },
        ),
      );
    }

    // 2. Thêm các hợp đồng sắp hết hạn
    expiringContractsAsync.whenData((contracts) {
      final expiring = contracts.take(2).toList();
      for (final c in expiring) {
        taskTiles.add(
          _buildTaskItem(
            context: context,
            icon: Icons.assignment_outlined,
            iconBg: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.1),
            iconColor: Theme.of(context).colorScheme.tertiary,
            type: 'Hợp đồng',
            room: 'P.${c.roomNumber ?? '—'}',
            detail:
                'Hết hạn vào: ${DateFormatter.format(DateFormatter.tryParse(c.endDate))}',
            statusWidget: const StatusChip(
              status: 'DRAFT',
              label: 'Sắp hết hạn',
            ),
            onTap: () => context.go(AppRoutes.adminContracts),
          ),
        );
      }
    });

    if (taskTiles.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Không có công việc cần xử lý',
              style: AppTextStyles.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Column(children: taskTiles);
  }

  Widget _buildTaskItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String type,
    required String room,
    required String detail,
    required Widget statusWidget,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Text(
              room,
              style: AppTextStyles.titleSm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            detail,
            style: AppTextStyles.bodySm.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusWidget,
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản admin không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: AppColors.danger),
              ),
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
  }
}
