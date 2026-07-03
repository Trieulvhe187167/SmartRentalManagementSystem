import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/maintenance_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

class AdminMaintenanceManagementScreen extends ConsumerStatefulWidget {
  const AdminMaintenanceManagementScreen({super.key});

  @override
  ConsumerState<AdminMaintenanceManagementScreen> createState() => _AdminMaintenanceManagementScreenState();
}

class _AdminMaintenanceManagementScreenState extends ConsumerState<AdminMaintenanceManagementScreen> {
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
      ref.read(adminMaintenanceProvider.notifier).fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminMaintenanceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Yêu cầu sửa chữa'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(adminMaintenanceProvider.notifier).fetchRequests(refresh: true);
        },
        child: Column(
          children: [
            // ─── Filter Status Chips ────────────────────
            Container(
              height: 60,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildFilterChip('ALL', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('OPEN', 'Chờ tiếp nhận'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RECEIVED', 'Đã tiếp nhận'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IN_PROGRESS', 'Đang sửa chữa'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RESOLVED', 'Đã hoàn thành'),
                  const SizedBox(width: 8),
                  _buildFilterChip('REJECTED', 'Từ chối'),
                ],
              ),
            ),

            // ─── Requests list ───────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (context, index) => const CardShimmer(height: 100),
                    )
                  : state.error != null
                      ? ErrorState(
                          message: 'Lỗi tải yêu cầu: ${state.error}',
                          onRetry: () => ref.read(adminMaintenanceProvider.notifier).fetchRequests(refresh: true),
                        )
                      : state.items.isEmpty
                          ? const EmptyState(
                              title: 'Không có yêu cầu sửa chữa nào',
                              subtitle: 'Chưa có khách thuê nào gửi yêu cầu bảo trì',
                              icon: Icons.build_outlined,
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
                                final item = state.items[index];
                                return _buildMaintenanceCard(context, item);
                              },
                            ),
            ),
          ],
        ),
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
          ref.read(adminMaintenanceProvider.notifier).updateStatus(value);
        }
      },
    );
  }

  Widget _buildMaintenanceCard(BuildContext context, MaintenanceRequest item) {
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
              'Phòng ${item.roomNumber ?? '—'}',
              style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
            ),
            StatusChip(status: item.status ?? 'OPEN'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Sự cố: ${item.title}',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Khách: ${item.tenantName} · ${DateFormatter.format(DateFormatter.tryParse(item.requestDate))}',
              style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            PriorityChip(priority: item.priority ?? 'MEDIUM'),
          ],
        ),
        onTap: () => _showMaintenanceDetailSheet(context, item),
      ),
    );
  }

  void _showMaintenanceDetailSheet(BuildContext context, MaintenanceRequest item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _MaintenanceDetailView(
          item: item,
          onRefreshList: () => ref.read(adminMaintenanceProvider.notifier).fetchRequests(refresh: true),
        );
      },
    );
  }
}

class _MaintenanceDetailView extends ConsumerStatefulWidget {
  final MaintenanceRequest item;
  final VoidCallback onRefreshList;

  const _MaintenanceDetailView({required this.item, required this.onRefreshList});

  @override
  ConsumerState<_MaintenanceDetailView> createState() => _MaintenanceDetailViewState();
}

class _MaintenanceDetailViewState extends ConsumerState<_MaintenanceDetailView> {
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatusAction(String action) async {
    final notes = _notesCtrl.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền nội dung xử lý vào ô ghi chú!'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await ref
        .read(adminMaintenanceProvider.notifier)
        .updateStatusAction(widget.item.id!, action, notes);
    setState(() => _submitting = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
      } else {
        Navigator.pop(context);
        widget.onRefreshList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái yêu cầu'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.item.status?.toUpperCase() ?? 'OPEN';
    final isPending = status == 'OPEN' || status == 'PENDING';
    final isReceived = status == 'RECEIVED';
    final isProgress = status == 'IN_PROGRESS';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                      'Phòng ${widget.item.roomNumber ?? '—'} · ${widget.item.title}',
                      style: AppTextStyles.headlineSm,
                    ),
                  ),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Mã sự cố: ${widget.item.requestCode ?? '—'} · Người gửi: ${widget.item.tenantName}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Priority & Category details
              Row(
                children: [
                  Expanded(child: _buildDetailCol('Mức độ', PriorityChip(priority: widget.item.priority ?? 'MEDIUM'))),
                  Expanded(child: _buildDetailCol('Danh mục', Text(widget.item.category ?? 'Khác', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)))),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Ngày gửi', DateFormatter.formatDateTime(DateFormatter.tryParse(widget.item.requestDate))),
              if (widget.item.resolvedDate != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Ngày giải quyết', DateFormatter.formatDateTime(DateFormatter.tryParse(widget.item.resolvedDate))),
              ],

              const SizedBox(height: 20),
              Text('Nội dung sự cố chi tiết:', style: AppTextStyles.titleSm),
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
                  widget.item.description ?? 'Không có mô tả chi tiết',
                  style: AppTextStyles.bodyMd,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Action buttons & note
              if (isPending || isReceived || isProgress) ...[
                Text('Cập nhật xử lý (Ghi chú bắt buộc)', style: AppTextStyles.titleSm),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú cập nhật',
                    hintText: 'Nhập nội dung chẩn đoán hoặc kết quả sửa chữa...',
                  ),
                ),
                const SizedBox(height: 20),
                if (_submitting)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      if (isPending) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatusAction('RECEIVE'),
                            child: const Text('Tiếp nhận'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                            onPressed: () => _updateStatusAction('REJECT'),
                            child: const Text('Từ chối'),
                          ),
                        ),
                      ],
                      if (isReceived) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatusAction('PROGRESS'),
                            child: const Text('Bắt đầu sửa'),
                          ),
                        ),
                      ],
                      if (isProgress) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatusAction('RESOLVE'),
                            child: const Text('Hoàn thành'),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ],
          ),
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

  Widget _buildDetailCol(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
