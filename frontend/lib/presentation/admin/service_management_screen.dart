import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/service_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';

final adminServicesProvider = FutureProvider<List<ServiceItem>>((ref) async {
  return AdminRepository.instance.services();
});

class AdminServiceManagementScreen extends ConsumerStatefulWidget {
  const AdminServiceManagementScreen({super.key});

  @override
  ConsumerState<AdminServiceManagementScreen> createState() => _AdminServiceManagementScreenState();
}

class _AdminServiceManagementScreenState extends ConsumerState<AdminServiceManagementScreen> {
  String _chargeTypeFor(String type) {
    switch (type) {
      case 'ELECTRICITY':
      case 'WATER':
        return 'METERED';
      default:
        return 'FIXED_PER_ROOM';
    }
  }

  void _showAddServiceSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'ELECTRICITY';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thêm dịch vụ mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên dịch vụ *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Loại dịch vụ *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ELECTRICITY', child: Text('Điện')),
                  DropdownMenuItem(value: 'WATER', child: Text('Nước')),
                  DropdownMenuItem(value: 'INTERNET', child: Text('Internet')),
                  DropdownMenuItem(value: 'CLEANING', child: Text('Vệ sinh')),
                  DropdownMenuItem(value: 'PARKING', child: Text('Gửi xe')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Khác (Vệ sinh, gửi xe...)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => type = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: 'Đơn vị tính * (ví dụ: kWh, m3, tháng)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || unitCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đủ tên và đơn vị tính')),
                    );
                    return;
                  }
                  try {
                    await AdminRepository.instance.createService(
                      ServiceRequest(
                        name: nameCtrl.text.trim(),
                        code: type,
                        type: type,
                        chargeType: _chargeTypeFor(type),
                        unit: unitCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        active: true,
                      ),
                    );
                    ref.invalidate(adminServicesProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm dịch vụ thành công'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Thêm dịch vụ', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdatePriceSheet(BuildContext context, ServiceItem service) {
    final priceCtrl = TextEditingController();
    DateTime effectiveDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cập nhật bảng giá - ${service.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giá mới (₫/${service.unit ?? ""}) *',
                  border: const OutlineInputBorder(),
                  suffixText: '₫',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Ngày áp dụng giá mới *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() {
                      effectiveDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.format(DateFormatter.tryParse(effectiveDate.toIso8601String())),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final serviceId = service.id;
                  final price = double.tryParse(
                    priceCtrl.text.trim().replaceAll('.', '').replaceAll(',', ''),
                  );
                  if (serviceId == null || price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập giá hợp lệ'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }
                  try {
                    await AdminRepository.instance.addServicePrice(
                      ServicePriceRequest(
                        serviceId: serviceId,
                        unitPrice: price,
                        effectiveFrom: effectiveDate.toIso8601String().substring(0, 10),
                        notes: 'Cập nhật giá từ màn quản lý dịch vụ',
                      ),
                    );
                    ref.invalidate(adminServicesProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật giá dịch vụ thành công'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Áp dụng giá mới', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceIcon(String? type) {
    switch (type) {
      case 'ELECTRICITY':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.bolt, color: Colors.amber, size: 26),
        );
      case 'WATER':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.water_drop, color: Colors.blue, size: 26),
        );
      case 'INTERNET':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.wifi, color: Colors.purple, size: 26),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.cleaning_services, color: Colors.grey, size: 26),
        );
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'ELECTRICITY':
        return 'Điện';
      case 'WATER':
        return 'Nước';
      case 'INTERNET':
        return 'Internet';
      default:
        return 'Dịch vụ khác';
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(adminServicesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý Dịch vụ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
            onPressed: () => _showAddServiceSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const PageLoading(),
        error: (err, stack) => ErrorState(
          message: 'Không thể tải danh sách dịch vụ: $err',
          onRetry: () => ref.invalidate(adminServicesProvider),
        ),
        data: (services) {
          final total = services.length;
          final active = services.where((s) => s.active == true).length;
          final inactive = total - active;

          return Column(
            children: [
              // ─── Stats Row ──────────────────────────────────
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.layers, Colors.blue, total.toString(), 'Tổng dịch vụ'),
                    _buildStatItem(Icons.check_circle, Colors.green, active.toString(), 'Đang hoạt động'),
                    _buildStatItem(Icons.pause_circle, Colors.orange, inactive.toString(), 'Tạm dừng'),
                  ],
                ),
              ),

              // ─── List Services ──────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminServicesProvider);
                  },
                  child: services.isEmpty
                      ? const EmptyState(title: 'Chưa có cấu hình dịch vụ nào')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: services.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final s = services[index];
                            final isServiceActive = s.active == true;

                            return AppCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        _serviceIcon(s.type),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(s.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                  StatusChip(status: isServiceActive ? 'ACTIVE' : 'INACTIVE'),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Loại: ${_typeLabel(s.type)} · Đơn vị: ${s.unit ?? "-"}',
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (s.id == null) return;
                                            try {
                                              await AdminRepository.instance.setServiceActive(
                                                s.id!,
                                                value == 'activate',
                                              );
                                              ref.invalidate(adminServicesProvider);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Đã cập nhật trạng thái dịch vụ'), backgroundColor: AppColors.success),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: isServiceActive ? 'deactivate' : 'activate',
                                              child: Text(isServiceActive ? 'Tạm dừng dịch vụ' : 'Kích hoạt hoạt động'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Đơn giá hiện hành', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text(
                                              s.currentPrice != null
                                                  ? '${CurrencyFormatter.format(s.currentPrice!)} / ${s.unit ?? ""}'
                                                  : 'Chưa thiết lập giá',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isServiceActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                                                decoration: isServiceActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => _showUpdatePriceSheet(context, s),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Cập nhật giá', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServiceSheet(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm dịch vụ', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
