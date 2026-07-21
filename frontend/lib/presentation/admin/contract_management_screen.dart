import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/api/api_client.dart';
import '../../data/models/contract_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

class AdminContractManagementScreen extends ConsumerStatefulWidget {
  const AdminContractManagementScreen({super.key});

  @override
  ConsumerState<AdminContractManagementScreen> createState() =>
      _AdminContractManagementScreenState();
}

class _AdminContractManagementScreenState
    extends ConsumerState<AdminContractManagementScreen> {
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
          ref
              .read(adminContractsProvider.notifier)
              .fetchContracts(refresh: true);
        },
        child: Column(
          children: [
            // ─── Filter Status Bar ───────────────────────
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
                  _buildFilterChip(
                    'PENDING_CONFIRMATION',
                    'Chờ khách xác nhận',
                  ),
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
                      itemBuilder: (context, index) =>
                          const CardShimmer(height: 120),
                    )
                  : state.error != null
                  ? ErrorState(
                      message: 'Lỗi tải hợp đồng: ${state.error}',
                      onRetry: () => ref
                          .read(adminContractsProvider.notifier)
                          .fetchContracts(refresh: true),
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
                      itemCount:
                          state.items.length + (state.isLoadingMore ? 1 : 0),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Số HĐ: ${contract.contractNumber ?? '—'}',
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: contract.status ?? 'ACTIVE'),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Phòng: ${contract.roomNumber} · Khách: ${contract.tenantName}',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thời hạn: ${DateFormatter.format(DateFormatter.tryParse(contract.startDate))} - ${DateFormatter.format(DateFormatter.tryParse(contract.endDate))}',
                style: AppTextStyles.bodySm.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Giá thuê: ${CurrencyFormatter.format(contract.monthlyRent)}/tháng',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Đang ở: ${contract.currentOccupantCount ?? 1}/${contract.maxOccupants ?? '--'} người',
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
          onTap: () => _showContractDetailSheet(context, contract),
        ),
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
                  _buildDetailRow(
                    'Giá thuê phòng',
                    '${CurrencyFormatter.format(contract.monthlyRent)}/tháng',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Tiền đặt cọc',
                    CurrencyFormatter.format(contract.deposit),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Ngày bắt đầu',
                    DateFormatter.format(
                      DateFormatter.tryParse(contract.startDate),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Ngày kết thúc',
                    DateFormatter.format(
                      DateFormatter.tryParse(contract.endDate),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Số người đang ở',
                    '${contract.currentOccupantCount ?? 1}/${contract.maxOccupants ?? '--'} người',
                  ),
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
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(contract.notes!, style: AppTextStyles.bodyMd),
                    ),
                  ],
                  if (contract.id != null) ...[
                    const SizedBox(height: 24),
                    _OccupantManagementSection(contract: contract),
                  ],
                  const SizedBox(height: 32),
                  if (contract.status?.toUpperCase() == 'ACTIVE')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _showTerminateDialog(context, contract.id!),
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

                final nowStr = DateTime.now().toIso8601String().substring(
                  0,
                  10,
                );
                final error = await ref
                    .read(adminContractsProvider.notifier)
                    .terminate(contractId, reason, nowStr);

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
                        content: Text('Đã kết thúc hợp đồng thuê'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Chấp nhận',
                style: TextStyle(color: AppColors.danger),
              ),
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
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

class _OccupantManagementSection extends StatefulWidget {
  final RentalContract contract;

  const _OccupantManagementSection({required this.contract});

  @override
  State<_OccupantManagementSection> createState() =>
      _OccupantManagementSectionState();
}

class _OccupantManagementSectionState
    extends State<_OccupantManagementSection> {
  late Future<List<ContractOccupant>> _occupantsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _occupantsFuture = AdminRepository.instance.contractOccupants(
      widget.contract.id!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContractOccupant>>(
      future: _occupantsFuture,
      builder: (context, snapshot) {
        final occupants = snapshot.data ?? const <ContractOccupant>[];
        final activeCount = occupants.where((item) => item.isActive).length;
        final currentCount = 1 + activeCount;
        final capacity = widget.contract.maxOccupants;
        final canAdd = capacity == null || currentCount < capacity;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Người đang ở ($currentCount/${capacity ?? '--'})',
                    style: AppTextStyles.titleMd,
                  ),
                ),
                IconButton(
                  tooltip: 'Thêm người ở cùng',
                  onPressed: !_busy && canAdd ? _addOccupant : null,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                ),
              ],
            ),
            Text(
              'Sức chứa tối đa: ${capacity ?? '--'} người',
              style: AppTextStyles.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  _personRow(
                    name: widget.contract.tenantName ?? 'Người thuê chính',
                    relationship: 'Người thuê chính',
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting) ...[
                    const Divider(height: 20),
                    const LinearProgressIndicator(),
                  ] else if (snapshot.hasError) ...[
                    const Divider(height: 20),
                    TextButton.icon(
                      onPressed: () => setState(_reload),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại danh sách người ở'),
                    ),
                  ] else
                    ...occupants.map(
                      (occupant) => Column(
                        children: [
                          const Divider(height: 20),
                          _personRow(
                            name: occupant.fullName,
                            relationship: occupant.isActive
                                ? occupant.relationship
                                : occupant.hasMovedOut
                                ? '${occupant.relationship} · Đã chuyển đi'
                                : '${occupant.relationship} · Chưa vào ở',
                            trailing:
                                occupant.isActive && occupant.occupantId != null
                                ? IconButton(
                                    tooltip: 'Đánh dấu đã chuyển đi',
                                    onPressed: _busy
                                        ? null
                                        : () => _moveOut(occupant),
                                    icon: const Icon(Icons.logout, size: 20),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (!canAdd) ...[
              const SizedBox(height: 8),
              Text(
                'Phòng đã đạt sức chứa tối đa.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.warning),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _personRow({
    required String name,
    required String relationship,
    Widget? trailing,
  }) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          child: Icon(Icons.person_outline, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.titleSm),
              Text(relationship, style: AppTextStyles.bodySm),
            ],
          ),
        ),
        ...switch (trailing) {
          null => const <Widget>[],
          final trailingWidget => <Widget>[trailingWidget],
        },
      ],
    );
  }

  Future<void> _addOccupant() async {
    final request = await _showAddOccupantDialog();
    if (request == null) return;
    await _runAction(
      () => AdminRepository.instance.createContractOccupant(
        widget.contract.id!,
        request,
      ),
      'Đã thêm người ở cùng.',
    );
  }

  Future<void> _moveOut(ContractOccupant occupant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận chuyển đi'),
        content: Text('Đánh dấu ${occupant.fullName} đã chuyển đi từ hôm nay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(
      () => AdminRepository.instance.moveOutContractOccupant(
        contractId: widget.contract.id!,
        occupantId: occupant.occupantId!,
      ),
      'Đã cập nhật ngày chuyển đi.',
    );
  }

  Future<void> _runAction(
    Future<ContractOccupant> Function() action,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Không thể cập nhật người ở. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ContractOccupantCreateRequest?> _showAddOccupantDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    final identityController = TextEditingController();
    DateTime moveInDate = DateTime.now();

    final result = await showDialog<ContractOccupantCreateRequest>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm người ở cùng'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Quan hệ với người thuê *',
                        hintText: 'Vợ/chồng, anh/chị/em, bạn...',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập mối quan hệ'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: identityController,
                      decoration: const InputDecoration(labelText: 'Số CCCD'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: moveInDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => moveInDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày vào ở',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DateFormatter.format(moveInDate)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  ContractOccupantCreateRequest(
                    fullName: nameController.text.trim(),
                    relationship: relationshipController.text.trim(),
                    moveInDate: moveInDate.toIso8601String().substring(0, 10),
                    phone: phoneController.text.trim(),
                    identityNumber: identityController.text.trim(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm người'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    relationshipController.dispose();
    phoneController.dispose();
    identityController.dispose();
    return result;
  }
}
