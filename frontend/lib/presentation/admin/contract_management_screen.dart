import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/contract_models.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

class AdminContractManagementScreen extends ConsumerStatefulWidget {
  const AdminContractManagementScreen({super.key});

  @override
  ConsumerState<AdminContractManagementScreen> createState() => _AdminContractManagementScreenState();
}

class _AdminContractManagementScreenState extends ConsumerState<AdminContractManagementScreen> {
  final _scrollController = ScrollController();
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminContractsProvider.notifier).fetchContracts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminContractsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý hợp đồng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            onPressed: () => context.push(AppRoutes.adminCreateContract),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(adminContractsProvider.notifier).fetchContracts(refresh: true);
        },
        child: Column(
          children: [
            // ─── Filter Status Bar ───────────────────────
            Container(
              height: 60,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildFilterChip('ALL', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ACTIVE', 'Đang hiệu lực'),
                  const SizedBox(width: 8),
                  _buildFilterChip('TERMINATED', 'Đã chấm dứt'),
                  const SizedBox(width: 8),
                  _buildFilterChip('EXPIRED', 'Hết hạn'),
                ],
              ),
            ),

            // ─── Contract List ───────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (context, index) => const CardShimmer(height: 120),
                    )
                  : state.error != null
                      ? ErrorState(
                          message: 'Lỗi tải hợp đồng: ${state.error}',
                          onRetry: () => ref.read(adminContractsProvider.notifier).fetchContracts(refresh: true),
                        )
                      : state.items.isEmpty
                          ? const EmptyState(
                              title: 'Không tìm thấy hợp đồng nào',
                              subtitle: 'Bấm nút + để tạo hợp đồng thuê mới',
                              icon: Icons.description_outlined,
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(20),
                              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.items.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final contract = state.items[index];
                                return _buildContractCard(context, contract);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () => context.push(AppRoutes.adminCreateContract),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
          ref.read(adminContractsProvider.notifier).updateStatus(value);
        }
      },
    );
  }

  Widget _buildContractCard(BuildContext context, RentalContract contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Số HĐ: ${contract.contractNumber ?? '—'}',
              style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
            ),
            StatusChip(status: contract.status ?? 'ACTIVE'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Phòng: ${contract.roomNumber} · Khách: ${contract.tenantName}',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Thời hạn: ${DateFormatter.format(DateFormatter.tryParse(contract.startDate))} - ${DateFormatter.format(DateFormatter.tryParse(contract.endDate))}',
              style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              'Giá thuê: ${CurrencyFormatter.format(contract.monthlyRent)}/tháng',
              style: AppTextStyles.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _showContractDetailSheet(context, contract),
      ),
    );
  }

  void _showContractDetailSheet(BuildContext context, RentalContract contract) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Hợp đồng: ${contract.contractNumber ?? '—'}',
                          style: AppTextStyles.headlineSm,
                        ),
                      ),
                      StatusChip(status: contract.status ?? 'ACTIVE'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildDetailRow('Số phòng', 'Phòng ${contract.roomNumber}'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tên khách thuê', contract.tenantName ?? '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Giá thuê phòng', '${CurrencyFormatter.format(contract.monthlyRent)}/tháng'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tiền đặt cọc', CurrencyFormatter.format(contract.deposit)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Ngày bắt đầu', DateFormatter.format(DateFormatter.tryParse(contract.startDate))),
                  const SizedBox(height: 12),
                  _buildDetailRow('Ngày kết thúc', DateFormatter.format(DateFormatter.tryParse(contract.endDate))),
                  if (contract.notes != null && contract.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Ghi chú hợp đồng:', style: AppTextStyles.titleSm),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Text(
                        contract.notes!,
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (contract.status?.toUpperCase() == 'ACTIVE')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showTerminateDialog(context, contract.id!),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Chấm dứt hợp đồng'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTerminateDialog(BuildContext context, int contractId) {
    Navigator.pop(context); // close bottom sheet first
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Chấm dứt hợp đồng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập lý do kết thúc sớm hợp đồng thuê phòng này:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lý do chấm dứt',
                  hintText: 'Ví dụ: Khách dọn đi sớm...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) return;

                final nowStr = DateTime.now().toIso8601String().substring(0, 10);
                final error = await ref
                    .read(adminContractsProvider.notifier)
                    .terminate(contractId, reason, nowStr);

                if (context.mounted) {
                  Navigator.pop(context);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: AppColors.error),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã kết thúc hợp đồng thuê'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Chấp nhận', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
