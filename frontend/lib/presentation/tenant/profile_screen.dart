import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../auth/auth_controller.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'tenant_controller.dart';

final tenantProfileUserProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(authRepositoryProvider).me();
});

class TenantProfileScreen extends ConsumerWidget {
  const TenantProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authControllerProvider);
    final userAsync = ref.watch(tenantProfileUserProvider);
    final user = userAsync.asData?.value ?? userState.user;
    final dashboardAsync = ref.watch(tenantDashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── Sliver App Bar Header ────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                user?.displayName ?? 'Khách thuê',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(50),
                      child: Text(
                        user?.initials ?? 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Scrollable Profile Body ──────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Contact Info Card ───────────────────
                  Text('Thông tin cá nhân', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.person_outline, 'Tên đăng nhập', user?.username ?? '—'),
                        const Divider(),
                        _buildInfoRow(context, Icons.email_outlined, 'Email', user?.email ?? '—'),
                        const Divider(),
                        _buildInfoRow(context, Icons.phone_outlined, 'Số điện thoại', user?.phone ?? '—'),
                        const Divider(),
                        _buildInfoRow(context, Icons.badge_outlined, 'CMND/CCCD', user?.idNumber ?? '—'),
                        const Divider(),
                        _buildInfoRow(context, Icons.location_on_outlined, 'Địa chỉ thường trú', user?.address ?? '—'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Current Room details card ───────────
                  Text('Thông tin thuê phòng', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  dashboardAsync.when(
                    data: (data) {
                      final room = data.currentRoom;
                      if (room == null) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Không có thông tin phòng đang thuê hiện tại.',
                              style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            _buildInfoRow(context, Icons.meeting_room_outlined, 'Số phòng', 'Phòng ${room.roomNumber}'),
                            const Divider(),
                            _buildInfoRow(context, Icons.layers_outlined, 'Tầng', room.floor != null ? 'Tầng ${room.floor}' : '—'),
                            const Divider(),
                            _buildInfoRow(context, Icons.apartment_outlined, 'Toà nhà', room.buildingName ?? '—'),
                            const Divider(),
                            _buildInfoRow(
                              context,
                              Icons.payments_outlined,
                              'Giá thuê hàng tháng',
                              CurrencyFormatter.format(room.monthlyRent),
                              valueColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const CardShimmer(height: 160),
                    error: (_, __) => AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Không thể tải thông tin phòng',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Actions Card ────────────────────────
                  Text('Tùy chọn', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Theme.of(context).brightness == Brightness.dark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: AppColors.secondary,
                          ),
                          title: const Text('Giao diện tối (Dark Mode)'),
                          trailing: Switch(
                            value: Theme.of(context).brightness == Brightness.dark,
                            onChanged: (v) {
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primaryContainer),
                          title: const Text('Đổi mật khẩu tài khoản'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => context.push(AppRoutes.changePassword),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout, color: AppColors.danger),
                          title: const Text('Đăng xuất khỏi tài khoản', style: TextStyle(color: AppColors.danger)),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  title: const Text('Đăng xuất'),
                                  content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.outline, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
