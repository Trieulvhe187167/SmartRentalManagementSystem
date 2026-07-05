import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/maintenance_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';

final adminMaintenanceDetailProvider = FutureProvider.family<MaintenanceRequest, int>((ref, id) async {
  return AdminRepository.instance.maintenanceRequest(id);
});

final adminMaintenanceUpdatesProvider = FutureProvider.family<List<MaintenanceUpdate>, int>((ref, id) async {
  try {
    final res = await AdminRepository.instance.maintenanceUpdates(id);
    return res.content;
  } catch (_) {
    return const [];
  }
});

class AdminMaintenanceDetailScreen extends ConsumerStatefulWidget {
  final int requestId;
  const AdminMaintenanceDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<AdminMaintenanceDetailScreen> createState() => _AdminMaintenanceDetailScreenState();
}

class _AdminMaintenanceDetailScreenState extends ConsumerState<AdminMaintenanceDetailScreen> {
  String _selectedAction = 'RESOLVED';
  final _notesCtrl = TextEditingController();
  DateTime _resolvedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  int _stepIndex(String? status) {
    switch (status) {
      case 'OPEN':
        return 0;
      case 'RECEIVED':
        return 1;
      case 'IN_PROGRESS':
        return 2;
      case 'RESOLVED':
        return 3;
      case 'REJECTED':
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _resolvedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _resolvedDate = picked;
      });
    }
  }

  Future<void> _updateStatus(String currentStatus) async {
    if (_notesCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ghi chú xử lý')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final notes = _notesCtrl.text.trim();
      switch (_selectedAction) {
        case 'RECEIVED':
          await AdminRepository.instance.receiveRequest(widget.requestId, notes);
          break;
        case 'IN_PROGRESS':
          await AdminRepository.instance.progressRequest(widget.requestId, notes);
          break;
        case 'RESOLVED':
          await AdminRepository.instance.resolveRequest(widget.requestId, notes);
          break;
        case 'REJECTED':
          await AdminRepository.instance.rejectRequest(widget.requestId, notes);
          break;
      }

      ref.invalidate(adminMaintenanceDetailProvider(widget.requestId));
      ref.invalidate(adminMaintenanceUpdatesProvider(widget.requestId));
      _notesCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(adminMaintenanceDetailProvider(widget.requestId));
    final updatesAsync = ref.watch(adminMaintenanceUpdatesProvider(widget.requestId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết Yêu cầu'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: requestAsync.when(
        loading: () => const PageLoading(),
        error: (err, stack) => ErrorState(
          message: 'Không thể tải yêu cầu sửa chữa: $err',
          onRetry: () => ref.invalidate(adminMaintenanceDetailProvider(widget.requestId)),
        ),
        data: (request) {
          final currentStep = _stepIndex(request.status);
          final isCompleted = request.status == 'RESOLVED' || request.status == 'REJECTED';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Progress Stepper ───────────────────────────
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIẾN ĐỘ XỬ LÝ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStep(0, 'Tiếp nhận', currentStep >= 0),
                          _buildStepLine(currentStep >= 1),
                          _buildStep(1, 'Xác nhận', currentStep >= 1),
                          _buildStepLine(currentStep >= 2),
                          _buildStep(2, 'Đang xử lý', currentStep >= 2),
                          _buildStepLine(currentStep >= 3),
                          _buildStep(3, request.status == 'REJECTED' ? 'Từ chối' : 'Hoàn thành', currentStep >= 3, isDanger: request.status == 'REJECTED'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Cards ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Card 1: Thông tin yêu cầu
                      _buildCard(
                        context: context,
                        icon: Icons.build,
                        title: 'Thông tin yêu cầu',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(context, Icons.tag, 'Mã yêu cầu', request.requestCode ?? '-', valueBold: true, valueColor: Theme.of(context).colorScheme.primary),
                            _infoRow(context, Icons.person, 'Khách thuê', request.tenantName ?? '-'),
                            _infoRow(context, Icons.room, 'Phòng', 'Phòng ${request.roomNumber ?? "-"}'),
                            _infoRow(context, Icons.category, 'Danh mục', request.category ?? '-'),
                            _infoRow(context, Icons.priority_high, 'Mức độ ưu tiên', request.priority ?? '-'),
                            _infoRow(context, Icons.calendar_today, 'Ngày gửi', request.requestDate != null ? DateFormatter.format(DateFormatter.tryParse(request.requestDate)) : '-'),
                            const Divider(height: 24),
                            Text(
                              'Mô tả chi tiết',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              request.description ?? 'Không có mô tả',
                              style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Lịch sử xử lý / Cập nhật
                      _buildCard(
                        context: context,
                        icon: Icons.history,
                        title: 'Lịch sử xử lý',
                        child: updatesAsync.when(
                          loading: () => const CardShimmer(),
                          error: (e, _) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Không thể tải lịch sử cập nhật.', style: TextStyle(color: Colors.grey)),
                          ),
                          data: (updates) => updates.isNotEmpty
                              ? ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: updates.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final update = updates[index];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: _getStatusColor(update.status),
                                            size: 20,
                                          ),
                                          if (index < updates.length - 1)
                                            Container(
                                              width: 2,
                                              height: 40,
                                              color: Colors.grey[300],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getStatusText(update.status),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              update.updatedAt != null ? DateFormatter.format(DateFormatter.tryParse(update.updatedAt)) : '',
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            ),
                                            if (update.notes != null && update.notes!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Ghi chú: ${update.notes}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                              ),
                                            ],
                                            const SizedBox(height: 2),
                                            Text(
                                              'Người thực hiện: ${update.updatedBy ?? "Hệ thống"}',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                              : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Chưa có lịch sử cập nhật nào.', style: TextStyle(color: Colors.grey)),
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Form cập nhật trạng thái mới
                      if (!isCompleted)
                        _buildCard(
                          context: context,
                          icon: Icons.edit_note,
                          title: 'Cập nhật trạng thái',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chọn trạng thái mới *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (request.status == 'OPEN')
                                    _actionChip('RECEIVED', 'Tiếp nhận', Colors.purple),
                                  if (request.status == 'OPEN' || request.status == 'RECEIVED')
                                    _actionChip('IN_PROGRESS', 'Đang xử lý', Colors.blue),
                                  _actionChip('RESOLVED', 'Hoàn thành', Colors.green),
                                  _actionChip('REJECTED', 'Từ chối', Colors.red),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_selectedAction == 'RESOLVED') ...[
                                const Text('Ngày hoàn thành *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDate,
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
                                          DateFormatter.format(DateFormatter.tryParse(_resolvedDate.toIso8601String())),
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                        ),
                                        Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const Text('Ghi chú xử lý *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập chi tiết xử lý (ví dụ: đã sửa ống nước xong...)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tính năng thông báo khách thuê đang phát triển')),
                                        );
                                      },
                                      icon: const Icon(Icons.notifications),
                                      label: const Text('Thông báo KH'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : () => _updateStatus(request.status ?? 'OPEN'),
                                      icon: _isSubmitting
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Icon(Icons.save, color: Colors.white),
                                      label: const Text('Lưu cập nhật', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(int index, String label, bool isActive, {bool isDanger = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive
              ? (isDanger ? Colors.red : Theme.of(context).colorScheme.primary)
              : Colors.grey[200],
          child: Icon(
            index == 3 && isDanger ? Icons.close : Icons.check,
            color: isActive ? Colors.white : Colors.grey[500],
            size: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? (isDanger ? Colors.red : Theme.of(context).colorScheme.primary)
                : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[200],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String action, String label, Color color) {
    final isSelected = _selectedAction == action;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAction = action;
          });
        }
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'OPEN':
        return Colors.grey;
      case 'RECEIVED':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'OPEN':
        return 'Tạo yêu cầu mới';
      case 'RECEIVED':
        return 'Đã tiếp nhận yêu cầu';
      case 'IN_PROGRESS':
        return 'Đang tiến hành sửa chữa';
      case 'RESOLVED':
        return 'Đã hoàn thành sửa chữa';
      case 'REJECTED':
        return 'Từ chối xử lý';
      default:
        return 'Cập nhật trạng thái';
    }
  }
}
