import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/maintenance_models.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'tenant_controller.dart';

class TenantMaintenanceScreen extends ConsumerStatefulWidget {
  const TenantMaintenanceScreen({super.key});

  @override
  ConsumerState<TenantMaintenanceScreen> createState() =>
      _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState
    extends ConsumerState<TenantMaintenanceScreen> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(tenantMaintenanceProvider.notifier).fetchRequests();
    }
  }

  List<MaintenanceRequest> _filterRequests(List<MaintenanceRequest> items) {
    if (_selectedStatus == 'ALL') return items;
    return items
        .where((item) => item.status?.toUpperCase() == _selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantMaintenanceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Yêu cầu sửa chữa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            onPressed: () => _showCreateRequestSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(tenantMaintenanceProvider.notifier)
              .fetchRequests(refresh: true);
        },
        child: Column(
          children: [
            // ─── Filter Bar ──────────────────────────────
            Container(
              height: 60,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  _buildFilterChip('ALL', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('OPEN', 'Đang chờ'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IN_PROGRESS', 'Đang xử lý'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RESOLVED', 'Đã xử lý'),
                  const SizedBox(width: 8),
                  _buildFilterChip('REJECTED', 'Từ chối'),
                ],
              ),
            ),

            // ─── List of Requests ────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (context, index) =>
                          const CardShimmer(height: 100),
                    )
                  : state.error != null
                  ? ErrorState(
                      message: 'Lỗi: ${state.error}',
                      onRetry: () => ref
                          .read(tenantMaintenanceProvider.notifier)
                          .fetchRequests(refresh: true),
                    )
                  : _filterRequests(state.items).isEmpty
                  ? const EmptyState(
                      title: 'Không có yêu cầu sửa chữa nào',
                      subtitle:
                          'Bấm nút + góc trên bên phải để gửi yêu cầu mới',
                      icon: Icons.build_outlined,
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount:
                          _filterRequests(state.items).length +
                          (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filterRequests(state.items).length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final item = _filterRequests(state.items)[index];
                        return _buildRequestCard(context, item);
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
        onPressed: () => _showCreateRequestSheet(context),
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
        }
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, MaintenanceRequest item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title ?? 'Yêu cầu sửa chữa',
                  style: AppTextStyles.titleMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(status: item.status ?? 'OPEN'),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                item.description ?? 'Không có mô tả chi tiết',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriorityChip(priority: item.priority ?? 'MEDIUM'),
                  Text(
                    DateFormatter.format(
                      DateFormatter.tryParse(item.requestDate),
                    ),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _showRequestDetailSheet(context, item),
        ),
      ),
    );
  }

  void _showRequestDetailSheet(BuildContext context, MaintenanceRequest item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final canCancel =
            item.status?.toUpperCase() == 'OPEN' ||
            item.status?.toUpperCase() == 'PENDING' ||
            item.status?.toUpperCase() == 'RECEIVED';

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                          item.title ?? 'Yêu cầu sửa chữa',
                          style: AppTextStyles.headlineSm,
                        ),
                      ),
                      StatusChip(status: item.status ?? 'OPEN'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã yêu cầu: ${item.requestCode ?? '—'}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Danh mục',
                    _translateCategory(item.category),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Độ ưu tiên',
                    _translatePriority(item.priority),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Ngày gửi',
                    DateFormatter.formatDateTime(
                      DateFormatter.tryParse(item.requestDate),
                    ),
                  ),
                  if (item.resolvedDate != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Ngày giải quyết',
                      DateFormatter.formatDateTime(
                        DateFormatter.tryParse(item.resolvedDate),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Nội dung mô tả:', style: AppTextStyles.titleSm),
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
                      item.description ?? 'Không có mô tả chi tiết',
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (canCancel)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.5,
                        ),
                      ),
                      onPressed: () async {
                        final error = await ref
                            .read(tenantMaintenanceProvider.notifier)
                            .cancelRequest(item.id!);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hủy yêu cầu thành công'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy yêu cầu này'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CreateRequestForm(
          onSubmit: (title, description, priority, category) async {
            final error = await ref
                .read(tenantMaintenanceProvider.notifier)
                .createRequest(title, description, priority, category);
            if (context.mounted) {
              Navigator.pop(context);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gửi yêu cầu thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _translateCategory(String? cat) {
    switch (cat?.toUpperCase()) {
      case 'ELECTRICITY':
      case 'ĐIỆN':
        return 'Điện';
      case 'WATER':
      case 'NƯỚC':
        return 'Nước';
      case 'INFRASTRUCTURE':
      case 'CƠ SỞ VẬT CHẤT':
        return 'Cơ sở vật chất';
      default:
        return 'Khác';
    }
  }

  String _translatePriority(String? prio) {
    switch (prio?.toUpperCase()) {
      case 'HIGH':
      case 'KHẨN CẤP':
        return 'Khẩn cấp';
      case 'MEDIUM':
      case 'BÌNH THƯỜNG':
        return 'Bình thường';
      default:
        return 'Thấp';
    }
  }
}

class _CreateRequestForm extends StatefulWidget {
  final Function(
    String title,
    String description,
    String priority,
    String category,
  )
  onSubmit;

  const _CreateRequestForm({required this.onSubmit});

  @override
  State<_CreateRequestForm> createState() => _CreateRequestFormState();
}

class _CreateRequestFormState extends State<_CreateRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  String _category = 'ELECTRICITY';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Text('Tạo yêu cầu sửa chữa mới', style: AppTextStyles.headlineSm),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề yêu cầu',
                  hintText: 'Ví dụ: Hỏng bóng đèn nhà tắm',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Danh mục sự cố'),
                items: const [
                  DropdownMenuItem(
                    value: 'ELECTRICITY',
                    child: Text('Hệ thống điện'),
                  ),
                  DropdownMenuItem(
                    value: 'WATER',
                    child: Text('Hệ thống nước'),
                  ),
                  DropdownMenuItem(
                    value: 'INFRASTRUCTURE',
                    child: Text('Cơ sở vật chất'),
                  ),
                  DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Thấp')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Bình thường')),
                  DropdownMenuItem(value: 'HIGH', child: Text('Khẩn cấp')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _priority = v);
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText:
                      'Mô tả rõ sự cố xảy ra tại phòng nào, tình trạng hỏng hóc cụ thể...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập mô tả sự cố'
                    : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit(
                        _titleCtrl.text.trim(),
                        _descCtrl.text.trim(),
                        _priority,
                        _category,
                      );
                    }
                  },
                  child: const Text('Gửi yêu cầu sửa chữa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
