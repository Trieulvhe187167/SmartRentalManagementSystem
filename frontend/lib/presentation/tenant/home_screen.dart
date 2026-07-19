import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/auth_models.dart';
import '../auth/auth_controller.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'tenant_controller.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(tenantDashboardProvider);
    final userState = ref.watch(authControllerProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trang chủ'),
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
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 26),
                unreadCountAsync.maybeWhen(
                  data: (count) => count > 0
                      ? Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            onPressed: () => context.go(AppRoutes.tenantNotifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tenantDashboardProvider);
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: dashboardAsync.when(
          data: (data) {
            final hasInvoice = data.currentInvoice != null;
            final debt = data.totalDebt ?? 0.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Welcome Header ───────────────────────
                  Row(
                    children: [
                      _buildUserAvatar(context, userState.user),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${userState.user?.displayName ?? 'Khách thuê'}!',
                              style: AppTextStyles.titleLg,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.currentRoom != null
                                  ? 'Phòng ${data.currentRoom!.roomNumber} · Tầng ${data.currentRoom!.floor} · ${data.currentRoom!.buildingName}'
                                  : 'Chưa có thông tin phòng',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Debt Alert Card ──────────────────────
                  if (debt > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.errorContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Khoản nợ chưa thanh toán',
                                  style: AppTextStyles.titleSm.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tổng tiền nợ hiện tại: ${CurrencyFormatter.format(debt)}',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ─── Current Invoice Card ────────────────
                  Text('Hóa đơn tháng này', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  if (hasInvoice) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hóa đơn tháng ${data.currentInvoice!.billingMonth}/${data.currentInvoice!.billingYear}',
                                style: AppTextStyles.titleMd,
                              ),
                              StatusChip(
                                status: data.currentInvoice!.status ?? 'DRAFT',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            CurrencyFormatter.format(
                              data.currentInvoice!.totalAmount,
                            ),
                            style: AppTextStyles.displaySm.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hạn nộp: ${DateFormatter.format(DateFormatter.tryParse(data.currentInvoice!.dueDate))}',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  AppRoutes.invoiceDetail(
                                    data.currentInvoice!.id!,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text('Xem chi tiết'),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppColors.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không có hóa đơn mới',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── Quick Actions Grid ──────────────────
                  Text('Tiện ích nhanh', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.receipt_long_outlined,
                        label: 'Hóa đơn',
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () => context.go(AppRoutes.tenantInvoices),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.build_outlined,
                        label: 'Sửa chữa',
                        color: Theme.of(context).colorScheme.secondary,
                        onTap: () => context.go(AppRoutes.tenantMaintenance),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.description_outlined,
                        label: 'Hợp đồng',
                        color: const Color(0xFF0891B2),
                        onTap: () => context.go(AppRoutes.tenantContract),
                      ),
                      _buildQuickAction(
                        context,
                        icon: Icons.person_outlined,
                        label: 'Hồ sơ',
                        color: Theme.of(context).colorScheme.outline,
                        onTap: () => context.go(AppRoutes.tenantProfile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Recent Maintenance ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yêu cầu sửa chữa gần đây',
                        style: AppTextStyles.titleLg,
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.tenantMaintenance),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Since dashboard doesn't return requests directly, let's load from maintenance provider
                  Consumer(
                    builder: (context, ref, child) {
                      final maintState = ref.watch(tenantMaintenanceProvider);
                      if (maintState.isLoading) {
                        return const CardShimmer(height: 80);
                      }
                      if (maintState.items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Chưa có yêu cầu sửa chữa nào',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final recent = maintState.items.take(2).toList();
                      return Column(
                        children: recent.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                title: Text(
                                  item.title ?? 'Yêu cầu sửa chữa',
                                  style: AppTextStyles.titleSm,
                                ),
                                subtitle: Text(
                                  'Ngày gửi: ${DateFormatter.format(DateFormatter.tryParse(item.requestDate))}',
                                  style: AppTextStyles.bodySm,
                                ),
                                trailing: StatusChip(
                                  status: item.status ?? 'OPEN',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const PageLoading(message: 'Đang tải dữ liệu...'),
          error: (err, stack) => ErrorState(
            message: 'Không thể tải thông tin trang chủ',
            onRetry: () => ref.read(tenantDashboardProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, UserResponse? user) {
    final avatarData = user?.avatarData;
    if (avatarData != null && avatarData.contains(',')) {
      try {
        final bytes = base64Decode(
          avatarData.substring(avatarData.indexOf(',') + 1),
        );
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildInitialsAvatar(context, user),
          ),
        );
      } catch (_) {}
    }
    return _buildInitialsAvatar(context, user);
  }

  Widget _buildInitialsAvatar(BuildContext context, UserResponse? user) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.primaryFixed,
      child: Text(
        user?.initials ?? 'U',
        style: AppTextStyles.titleLg.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showInvoicesBottomSheet(BuildContext context, WidgetRef ref) {
    ref.read(tenantInvoicesProvider.notifier).fetchInvoices(refresh: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Lịch sử hóa đơn', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final invoicesState = ref.watch(tenantInvoicesProvider);
                        if (invoicesState.isLoading &&
                            invoicesState.items.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (invoicesState.error != null &&
                            invoicesState.items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Lỗi tải hóa đơn: ${invoicesState.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          );
                        }
                        if (invoicesState.items.isEmpty) {
                          return const EmptyState(
                            title: 'Chưa có hóa đơn nào',
                            icon: Icons.receipt_long_outlined,
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: invoicesState.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final invoice = invoicesState.items[index];
                            final isPaid =
                                invoice.status?.toUpperCase() == 'PAID' ||
                                invoice.status?.toUpperCase() ==
                                    'ĐÃ THANH TOÁN';
                            return AppCard(
                              onTap: () {
                                Navigator.pop(context);
                                context.push(
                                  AppRoutes.invoiceDetail(invoice.id!),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          (isPaid
                                                  ? AppColors.success
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary)
                                              .withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.receipt_outlined,
                                      color: isPaid
                                          ? AppColors.success
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hóa đơn Tháng ${invoice.billingMonth}/${invoice.billingYear}',
                                          style: AppTextStyles.titleSm,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Hạn đóng: ${DateFormatter.format(DateFormatter.tryParse(invoice.dueDate))}',
                                          style: AppTextStyles.labelMd.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(
                                          invoice.totalAmount,
                                        ),
                                        style: AppTextStyles.titleSm.copyWith(
                                          color: isPaid
                                              ? AppColors.success
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      StatusChip(
                                        status: invoice.status ?? 'DRAFT',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
