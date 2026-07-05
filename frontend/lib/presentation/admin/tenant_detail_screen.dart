import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/tenant_models.dart';
import '../../data/models/invoice_models.dart';
import '../../data/models/maintenance_models.dart';
import '../../data/models/contract_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';

final adminTenantDetailProvider = FutureProvider.family<TenantProfile, int>((ref, id) async {
  return AdminRepository.instance.tenant(id);
});

final adminTenantInvoicesProvider = FutureProvider.family<List<Invoice>, int>((ref, tenantId) async {
  try {
    final res = await AdminRepository.instance.invoices(size: 5, tenantId: tenantId);
    return res.content;
  } catch (_) {
    return const [];
  }
});

final adminTenantMaintenanceProvider = FutureProvider.family<List<MaintenanceRequest>, int>((ref, tenantId) async {
  try {
    final res = await AdminRepository.instance.maintenanceRequests(size: 5, tenantId: tenantId);
    return res.content;
  } catch (_) {
    return const [];
  }
});

final adminTenantContractsProvider = FutureProvider.family<List<RentalContract>, int>((ref, tenantId) async {
  try {
    final res = await AdminRepository.instance.tenantContracts(tenantId, size: 5);
    return res.content;
  } catch (_) {
    return const [];
  }
});

class AdminTenantDetailScreen extends ConsumerStatefulWidget {
  final int tenantId;
  const AdminTenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<AdminTenantDetailScreen> createState() => _AdminTenantDetailScreenState();
}

class _AdminTenantDetailScreenState extends ConsumerState<AdminTenantDetailScreen> {
  bool _isDeactivating = false;

  Future<void> _deactivateTenant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận vô hiệu hoá'),
        content: const Text('Bạn có chắc chắn muốn vô hiệu hoá tài khoản khách thuê này không? Người dùng sẽ không thể đăng nhập vào hệ thống.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Vô hiệu hoá'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeactivating = true);
    try {
      await AdminRepository.instance.deactivateTenant(widget.tenantId);
      ref.invalidate(adminTenantDetailProvider(widget.tenantId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã vô hiệu hoá tài khoản khách thuê'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(adminTenantDetailProvider(widget.tenantId));
    final invoicesAsync = ref.watch(adminTenantInvoicesProvider(widget.tenantId));
    final maintenanceAsync = ref.watch(adminTenantMaintenanceProvider(widget.tenantId));
    final contractsAsync = ref.watch(adminTenantContractsProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết Khách thuê'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            enabled: !_isDeactivating,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng chỉnh sửa đang phát triển')),
                );
              } else if (value == 'deactivate') {
                _deactivateTenant();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa thông tin'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text('Vô hiệu hoá', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: tenantAsync.when(
        loading: () => const PageLoading(),
        error: (err, stack) => ErrorState(
          message: 'Không thể tải thông tin khách thuê: $err',
          onRetry: () => ref.invalidate(adminTenantDetailProvider(widget.tenantId)),
        ),
        data: (tenant) {
          final initials = tenant.fullName != null && tenant.fullName!.isNotEmpty
              ? tenant.fullName!.trim().split(' ').last.substring(0, 1).toUpperCase()
              : 'U';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Hero Section ─────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withBlue(220),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.fullName ?? 'Khách thuê',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: tenant.active == true
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tenant.active == true ? 'Đang hoạt động' : 'Vô hiệu hóa',
                                        style: TextStyle(
                                          color: tenant.active == true ? Colors.green[300] : Colors.red[300],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.room, size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      tenant.currentRoom != null ? 'Phòng ${tenant.currentRoom}' : 'Chưa nhận phòng',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Cards Body ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Card 1: Thông tin cá nhân
                          _buildCard(
                            context: context,
                            icon: Icons.person,
                            title: 'Thông tin cá nhân',
                            child: Column(
                              children: [
                                _infoRow(context, Icons.email, 'Email', tenant.email ?? '-'),
                                _infoRow(context, Icons.phone, 'Số điện thoại', tenant.phone ?? '-'),
                                _infoRow(context, Icons.badge, 'CMND/CCCD', tenant.idNumber ?? '-'),
                                _infoRow(context, Icons.credit_card, 'Loại giấy tờ', tenant.idType ?? 'CCCD'),
                                _infoRow(context, Icons.location_on, 'Địa chỉ', tenant.address ?? '-'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card 2: Hợp đồng hiện tại
                          _buildCard(
                            context: context,
                            icon: Icons.description,
                            title: 'Hợp đồng hiện tại',
                            child: contractsAsync.when(
                              loading: () => const CardShimmer(),
                              error: (e, _) => const Text('Không thể tải hợp đồng hiện tại'),
                              data: (contracts) {
                                RentalContract? current;
                                for (final contract in contracts) {
                                  if (contract.status == 'ACTIVE') {
                                    current = contract;
                                    break;
                                  }
                                }
                                current ??= contracts.isNotEmpty ? contracts.first : null;
                                if (current == null) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text('Khách thuê chưa có hợp đồng', style: TextStyle(color: Colors.grey)),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _infoRow(context, Icons.tag, 'Mã hợp đồng', current.contractNumber ?? 'HD-${current.id}', valueBold: true, valueColor: Theme.of(context).colorScheme.primary),
                                    _infoRow(context, Icons.calendar_today, 'Ngày bắt đầu', current.startDate != null ? DateFormatter.format(DateFormatter.tryParse(current.startDate)) : '-'),
                                    _infoRow(context, Icons.event, 'Ngày kết thúc', current.endDate != null ? DateFormatter.format(DateFormatter.tryParse(current.endDate)) : '-'),
                                    _infoRow(context, Icons.payments, 'Giá thuê', current.monthlyRent != null ? '${CurrencyFormatter.format(current.monthlyRent!)} / tháng' : '-', valueBold: true, valueColor: Theme.of(context).colorScheme.primary),
                                    _infoRow(context, Icons.savings, 'Tiền đặt cọc', current.deposit != null ? CurrencyFormatter.format(current.deposit!) : '-'),
                                    _infoRow(context, Icons.verified, 'Trạng thái', current.status ?? '-'),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card 3: Hóa đơn gần đây
                          _buildCard(
                            context: context,
                            icon: Icons.receipt_long,
                            title: 'Hóa đơn gần đây',
                            trailing: TextButton(
                              onPressed: () {},
                              child: const Text('Xem tất cả'),
                            ),
                            child: invoicesAsync.when(
                              loading: () => const CardShimmer(),
                              error: (e, _) => const Text('Không thể tải lịch sử hóa đơn'),
                              data: (invoices) {
                                if (invoices.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text('Chưa có hóa đơn nào phát hành', style: TextStyle(color: Colors.grey)),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: invoices.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final inv = invoices[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Tháng ${inv.billingMonth}/${inv.billingYear}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(inv.invoiceNumber ?? '', style: const TextStyle(fontSize: 12)),
                                      trailing: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(inv.totalAmount),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                          ),
                                          const SizedBox(height: 4),
                                          StatusChip(status: inv.status ?? 'UNPAID'),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card 4: Yêu cầu sửa chữa
                          _buildCard(
                            context: context,
                            icon: Icons.build,
                            title: 'Yêu cầu sửa chữa',
                            child: maintenanceAsync.when(
                              loading: () => const CardShimmer(),
                              error: (e, _) => const Text('Không thể tải danh sách sửa chữa'),
                              data: (requests) {
                                if (requests.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text('Chưa có yêu cầu sửa chữa nào', style: TextStyle(color: Colors.grey)),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: requests.length > 3 ? 3 : requests.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final req = requests[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(req.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(req.requestDate != null ? DateFormatter.format(DateFormatter.tryParse(req.requestDate)) : '', style: const TextStyle(fontSize: 12)),
                                      trailing: StatusChip(status: req.status ?? 'OPEN'),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Fixed Bottom Actions Bar ──────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng gửi thông báo đang phát triển')),
                            );
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('Gửi thông báo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chuyển sang màn hình Tạo hoá đơn...')),
                            );
                          },
                          icon: const Icon(Icons.add_circle, color: Colors.white),
                          label: const Text('Tạo hóa đơn', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold)),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, {bool valueBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
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
