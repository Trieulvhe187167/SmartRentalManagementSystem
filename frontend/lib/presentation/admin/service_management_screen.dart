import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/service_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────
final adminServicesProvider = FutureProvider<List<ServiceItem>>((ref) async {
  return AdminRepository.instance.services();
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class AdminServiceManagementScreen extends ConsumerStatefulWidget {
  const AdminServiceManagementScreen({super.key});

  @override
  ConsumerState<AdminServiceManagementScreen> createState() =>
      _AdminServiceManagementScreenState();
}

class _AdminServiceManagementScreenState
    extends ConsumerState<AdminServiceManagementScreen> {
  // ─── Helpers ─────────────────────────────────────────────────────────────
  String _chargeTypeFor(String type) {
    switch (type) {
      case 'ELECTRICITY':
      case 'WATER':
        return 'METERED';
      default:
        return 'FIXED_PER_ROOM';
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
      case 'PARKING':
        return 'Gửi xe';
      case 'CLEANING':
        return 'Vệ sinh';
      default:
        return 'Khác';
    }
  }

  _ServiceIconData _iconFor(String? type) {
    switch (type) {
      case 'ELECTRICITY':
        return _ServiceIconData(
          Icons.bolt,
          Colors.amber.shade600,
          Colors.amber.shade50,
          Colors.amber.shade100,
        );
      case 'WATER':
        return _ServiceIconData(
          Icons.water_drop,
          Colors.blue.shade600,
          Colors.blue.shade50,
          Colors.blue.shade100,
        );
      case 'INTERNET':
        return _ServiceIconData(
          Icons.wifi,
          Colors.purple.shade600,
          Colors.purple.shade50,
          Colors.purple.shade100,
        );
      case 'PARKING':
        return _ServiceIconData(
          Icons.directions_car,
          Colors.teal.shade600,
          Colors.teal.shade50,
          Colors.teal.shade100,
          symbol: 'P',
        );
      case 'CLEANING':
        return _ServiceIconData(
          Icons.delete,
          Colors.orange.shade600,
          Colors.orange.shade50,
          Colors.orange.shade100,
          symbol: 'R',
        );
      default:
        return _ServiceIconData(
          Icons.settings,
          Colors.grey.shade600,
          Colors.grey.shade100,
          Colors.grey.shade200,
          symbol: '₫',
        );
    }
  }

  // ─── Add Service Sheet ────────────────────────────────────────────────────
  void _showAddServiceSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'ELECTRICITY';
    DateTime effectiveDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DragHandle(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thêm dịch vụ mới', style: AppTextStyles.headlineSm),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SheetLabel('Tên dịch vụ *'),
                const SizedBox(height: 6),
                _sheetField(nameCtrl, 'Ví dụ: Tiền Điện, Tiền Nước...', ctx),
                const SizedBox(height: 14),
                _SheetLabel('Loại dịch vụ *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: _fieldDeco(null, ctx),
                  items: const [
                    DropdownMenuItem(
                      value: 'ELECTRICITY',
                      child: _ServiceTypeOption(Icons.bolt, 'Điện'),
                    ),
                    DropdownMenuItem(
                      value: 'WATER',
                      child: _ServiceTypeOption(Icons.water_drop, 'Nước'),
                    ),
                    DropdownMenuItem(
                      value: 'INTERNET',
                      child: _ServiceTypeOption(Icons.wifi, 'Internet'),
                    ),
                    DropdownMenuItem(
                      value: 'CLEANING',
                      child: _ServiceTypeOption.symbol('R', 'Vệ sinh'),
                    ),
                    DropdownMenuItem(
                      value: 'PARKING',
                      child: _ServiceTypeOption.symbol('P', 'Gửi xe'),
                    ),
                    DropdownMenuItem(
                      value: 'OTHER',
                      child: _ServiceTypeOption.symbol('₫', 'Khác'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => type = v);
                  },
                ),
                const SizedBox(height: 14),
                _SheetLabel('Đơn vị tính *'),
                const SizedBox(height: 6),
                _sheetField(unitCtrl, 'kWh, m³, tháng, người/tháng...', ctx),
                const SizedBox(height: 14),
                _SheetLabel('Đơn giá ban đầu *'),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDeco('Ví dụ: 30.000', ctx).copyWith(
                    suffixText: '₫',
                    suffixStyle: TextStyle(
                      color: Theme.of(ctx).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SheetLabel('Ngày áp dụng *'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: effectiveDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setS(() => effectiveDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormatter.format(
                            DateFormatter.tryParse(
                              effectiveDate.toIso8601String(),
                            ),
                          ),
                          style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SheetLabel('Mô tả (tuỳ chọn)'),
                const SizedBox(height: 6),
                _sheetField(descCtrl, 'Mô tả ngắn...', ctx, maxLines: 2),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    final initialPrice = double.tryParse(
                      priceCtrl.text
                          .trim()
                          .replaceAll('.', '')
                          .replaceAll(',', ''),
                    );
                    if (nameCtrl.text.trim().isEmpty ||
                        unitCtrl.text.trim().isEmpty ||
                        initialPrice == null ||
                        initialPrice <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng điền tên, đơn vị tính và đơn giá hợp lệ',
                          ),
                          backgroundColor: AppColors.danger,
                        ),
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
                          initialUnitPrice: initialPrice,
                          priceEffectiveFrom: effectiveDate
                              .toIso8601String()
                              .substring(0, 10),
                        ),
                      );
                      ref.invalidate(adminServicesProvider);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Thêm dịch vụ và giá ban đầu thành công',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Thêm dịch vụ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Update Price Sheet ───────────────────────────────────────────────────
  void _showUpdatePriceSheet(BuildContext context, ServiceItem service) {
    final messenger = ScaffoldMessenger.of(context);
    final priceCtrl = TextEditingController();
    DateTime effectiveDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thêm giá mới — ${service.name ?? ""}',
                      style: AppTextStyles.headlineSm,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SheetLabel('Giá mới (₫ / ${service.unit ?? ""})'),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _fieldDeco('Ví dụ: 3.800', ctx).copyWith(
                  suffixText: '₫',
                  suffixStyle: TextStyle(
                    color: Theme.of(ctx).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _SheetLabel('Ngày áp dụng'),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx,
                    initialDate: effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (p != null) setS(() => effectiveDate = p);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormatter.format(
                          DateFormatter.tryParse(
                            effectiveDate.toIso8601String(),
                          ),
                        ),
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: () async {
                  final id = service.id;
                  final price = double.tryParse(
                    priceCtrl.text
                        .trim()
                        .replaceAll('.', '')
                        .replaceAll(',', ''),
                  );
                  if (id == null || price == null || price <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập giá hợp lệ'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }
                  try {
                    await AdminRepository.instance.addServicePrice(
                      ServicePriceRequest(
                        serviceId: id,
                        unitPrice: price,
                        effectiveFrom: effectiveDate
                            .toIso8601String()
                            .substring(0, 10),
                        notes: 'Cập nhật giá từ quản lý dịch vụ',
                      ),
                    );
                    ref.invalidate(adminServicesProvider);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật giá thành công'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Xác nhận thay đổi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Toggle active ────────────────────────────────────────────────────────
  Future<void> _toggleActive(BuildContext context, ServiceItem service) async {
    if (service.id == null) return;
    final isActive = service.active == true;
    try {
      await AdminRepository.instance.setServiceActive(service.id!, !isActive);
      ref.invalidate(adminServicesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive ? 'Đã tạm dừng dịch vụ' : 'Đã kích hoạt dịch vụ',
            ),
            backgroundColor: isActive ? Colors.orange : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(adminServicesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          children: [
            Icon(Icons.room_service_outlined, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Quản lý Dịch vụ',
              style: AppTextStyles.headlineSm.copyWith(color: cs.primary),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showAddServiceSheet(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const PageLoading(),
        error: (err, _) => ErrorState(
          message: 'Không thể tải dịch vụ: $err',
          onRetry: () => ref.invalidate(adminServicesProvider),
        ),
        data: (services) {
          final total = services.length;
          final active = services.where((s) => s.active == true).length;
          final inactive = total - active;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminServicesProvider),
            child: CustomScrollView(
              slivers: [
                // ── Stats row ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.layers_outlined,
                              iconColor: Colors.blue.shade600,
                              iconBg: Colors.blue.shade50,
                              label: 'Tổng\ndịch vụ',
                              value: '$total',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle,
                              iconColor: Colors.green.shade600,
                              iconBg: Colors.green.shade50,
                              label: 'Hoạt\nđộng',
                              value: '$active',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.pause_circle_outline,
                              iconColor: Colors.orange.shade600,
                              iconBg: Colors.orange.shade50,
                              label: 'Tạm\ndừng',
                              value: '$inactive',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Section title ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Danh sách dịch vụ',
                      style: AppTextStyles.titleLg,
                    ),
                  ),
                ),

                // ── Services list ──────────────────────────────────
                services.isEmpty
                    ? const SliverFillRemaining(
                        child: EmptyState(
                          title: 'Chưa có cấu hình dịch vụ nào',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ServiceCard(
                                service: services[i],
                                iconData: _iconFor(services[i].type),
                                typeLabel: _typeLabel(services[i].type),
                                onUpdatePrice: () =>
                                    _showUpdatePriceSheet(context, services[i]),
                                onToggle: () =>
                                    _toggleActive(context, services[i]),
                              ),
                            ),
                            childCount: services.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServiceSheet(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm dịch vụ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  // ─── Input helpers ────────────────────────────────────────────────────────
  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    BuildContext ctx, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _fieldDeco(hint, ctx),
    );
  }

  InputDecoration _fieldDeco(String? hint, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(fontSize: 22, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final _ServiceIconData iconData;
  final String typeLabel;
  final VoidCallback onUpdatePrice;
  final VoidCallback onToggle;

  const _ServiceCard({
    required this.service,
    required this.iconData,
    required this.typeLabel,
    required this.onUpdatePrice,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = service.active == true;
    final priceText = service.currentPrice != null
        ? '${CurrencyFormatter.format(service.currentPrice!)} / ${service.unit ?? ""}'
        : 'Chưa thiết lập giá';

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Icon  +  Name & Badge  +  Popup ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon tròn
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isActive ? iconData.bg : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? iconData.border
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: iconData.symbol == null
                        ? Icon(
                            iconData.icon,
                            color: isActive
                                ? iconData.color
                                : Colors.grey.shade400,
                            size: 26,
                          )
                        : Center(
                            child: Text(
                              iconData.symbol!,
                              style: TextStyle(
                                color: isActive
                                    ? iconData.color
                                    : Colors.grey.shade400,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Name + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                service.name ?? '-',
                                style: AppTextStyles.bodyLg.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(active: isActive),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Loại: $typeLabel · ${service.unit ?? ""}',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Popup menu ⋮
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                    onSelected: (v) {
                      if (v == 'price') {
                        onUpdatePrice();
                      } else if (v == 'toggle') {
                        onToggle();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'price',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Cập nhật giá'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.pause_outlined
                                  : Icons.play_arrow_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive
                                  ? 'Tạm dừng dịch vụ'
                                  : 'Kích hoạt dịch vụ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── Row 2: Price  +  Action buttons ─────────────────
              Row(
                children: [
                  // Giá
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn giá hiện hành',
                          style: AppTextStyles.labelMd.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          priceText,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isActive ? cs.primary : cs.onSurfaceVariant,
                            decoration: isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 2 action chips
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionChip(
                        label: 'Cập nhật giá',
                        icon: Icons.edit_outlined,
                        color: cs.primary,
                        bgColor: cs.primary.withValues(alpha: 0.08),
                        onTap: onUpdatePrice,
                      ),
                      const SizedBox(width: 6),
                      _ActionChip(
                        label: isActive ? 'Tạm dừng' : 'Kích hoạt',
                        icon: isActive
                            ? Icons.pause_outlined
                            : Icons.play_arrow_outlined,
                        color: isActive
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                        bgColor: isActive
                            ? Colors.orange.withValues(alpha: 0.08)
                            : Colors.green.withValues(alpha: 0.08),
                        onTap: onToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Chip ──────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback onTap;
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        active ? 'Đang hoạt động' : 'Tạm dừng',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: active ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _ServiceTypeOption extends StatelessWidget {
  final IconData? icon;
  final String? symbol;
  final String label;

  const _ServiceTypeOption(IconData this.icon, this.label) : symbol = null;

  const _ServiceTypeOption.symbol(String this.symbol, this.label) : icon = null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 18)
        else
          SizedBox(
            width: 18,
            child: Text(
              symbol!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

// ─── Drag Handle ──────────────────────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

// ─── Sheet Label ──────────────────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelMd.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0,
        fontSize: 13,
      ),
    );
  }
}

// ─── Service Icon Data ────────────────────────────────────────────────────────
class _ServiceIconData {
  final IconData icon;
  final Color color, bg, border;
  final String? symbol;

  const _ServiceIconData(
    this.icon,
    this.color,
    this.bg,
    this.border, {
    this.symbol,
  });
}
