import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/contract_models.dart';
import '../../data/models/room_models.dart';
import '../../data/models/tenant_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

final availableRoomsProvider = FutureProvider.autoDispose<List<Room>>((
  ref,
) async {
  final res = await AdminRepository.instance.rooms(
    status: 'AVAILABLE',
    size: 100,
  );
  return res.content;
});

final activeTenantsProvider = FutureProvider.autoDispose<List<TenantProfile>>((
  ref,
) async {
  final tenantPage = await AdminRepository.instance.tenants(size: 100);
  final contractPage = await AdminRepository.instance.contracts(size: 100);
  final unavailableTenantIds = <int>{
    for (final contract in contractPage.content)
      if ((contract.status == 'ACTIVE' ||
              contract.status == 'PENDING_CONFIRMATION') &&
          contract.tenantProfileId != null)
        contract.tenantProfileId!,
  };
  return tenantPage.content
      .where((tenant) => !unavailableTenantIds.contains(tenant.id))
      .toList();
});

class AdminCreateContractScreen extends ConsumerStatefulWidget {
  const AdminCreateContractScreen({super.key});

  @override
  ConsumerState<AdminCreateContractScreen> createState() =>
      _AdminCreateContractScreenState();
}

class _AdminCreateContractScreenState
    extends ConsumerState<AdminCreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int? _selectedRoomId;
  int? _selectedTenantId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void dispose() {
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // auto set end date to 1 year later if null
        _endDate ??= DateTime(picked.year + 1, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate?.add(const Duration(days: 30)) ?? DateTime.now(),
      firstDate: _startDate?.add(const Duration(days: 1)) ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng trống'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khách thuê'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thời hạn hợp đồng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final req = ContractCreateRequest(
      roomId: _selectedRoomId!,
      tenantProfileId: _selectedTenantId!,
      startDate: _startDate!.toIso8601String().substring(0, 10),
      endDate: _endDate!.toIso8601String().substring(0, 10),
      monthlyRent: double.tryParse(_rentCtrl.text.trim()),
      deposit: double.tryParse(_depositCtrl.text.trim()),
      notes: _notesCtrl.text.trim(),
    );

    final error = await ref
        .read(adminContractsProvider.notifier)
        .createContract(req);

    setState(() => _submitting = false);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo và gửi hợp đồng cho khách thuê xác nhận.'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(availableRoomsProvider);
      ref.invalidate(adminRoomsProvider);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(availableRoomsProvider);
    final tenantsAsync = ref.watch(activeTenantsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tạo hợp đồng mới'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Room Selection ──────────────────────────
              Text('Chọn phòng và khách thuê', style: AppTextStyles.titleMd),
              const SizedBox(height: 12),
              roomsAsync.when(
                data: (rooms) => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Chọn phòng trống',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  initialValue: _selectedRoomId,
                  items: rooms.map((r) {
                    return DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        'Phòng ${r.roomNumber} - ${CurrencyFormatter.format(r.monthlyRent)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedRoomId = id;
                      if (id != null) {
                        final room = rooms.firstWhere((r) => r.id == id);
                        _rentCtrl.text = room.monthlyRent.toStringAsFixed(0);
                        _depositCtrl.text = room.monthlyRent.toStringAsFixed(
                          0,
                        ); // default deposit = 1 month rent
                      }
                    });
                  },
                ),
                loading: () => const LoadingShimmer(height: 52),
                error: (e, _) => Text(
                  'Lỗi tải phòng: $e',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 16),

              // Tenant Selection
              tenantsAsync.when(
                data: (tenants) => tenants.isEmpty
                    ? const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.person_off_outlined),
                        title: Text('Không còn khách thuê đủ điều kiện'),
                        subtitle: Text(
                          'Mỗi khách chỉ được có một hợp đồng hiệu lực hoặc đang chờ xác nhận.',
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Chọn khách hàng chưa có hợp đồng',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        initialValue: _selectedTenantId,
                        items: tenants.map((t) {
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text('${t.fullName} - ${t.phone}'),
                          );
                        }).toList(),
                        onChanged: (id) =>
                            setState(() => _selectedTenantId = id),
                      ),
                loading: () => const LoadingShimmer(height: 52),
                error: (e, _) => Text(
                  'Lỗi tải khách thuê: $e',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // ─── Contract Term Dates ─────────────────────
              Text('Thời hạn hợp đồng', style: AppTextStyles.titleMd),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày bắt đầu',
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Chọn ngày'
                              : DateFormatter.format(_startDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày kết thúc',
                        ),
                        child: Text(
                          _endDate == null
                              ? 'Chọn ngày'
                              : DateFormatter.format(_endDate),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // ─── Rental & Deposit Price ──────────────────
              Text('Giá thuê & Đặt cọc', style: AppTextStyles.titleMd),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiền thuê/tháng (VND)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập giá thuê'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _depositCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiền đặt cọc (VND)',
                        prefixIcon: Icon(Icons.savings_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập tiền cọc'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Điều khoản đặc biệt (ghi chú)',
                  hintText: 'Ví dụ: Đóng tiền vào ngày 5 hàng tháng...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Tạo và gửi khách xác nhận'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
