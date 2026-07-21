import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/api/api_client.dart';
import '../../data/models/contract_models.dart';
import '../../data/repositories/tenant_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/status_chip.dart';
import 'tenant_controller.dart';

class TenantContractScreen extends ConsumerStatefulWidget {
  const TenantContractScreen({super.key});

  @override
  ConsumerState<TenantContractScreen> createState() =>
      _TenantContractScreenState();
}

class _TenantContractScreenState extends ConsumerState<TenantContractScreen>
    with WidgetsBindingObserver {
  static const _refreshInterval = Duration(seconds: 10);

  bool _acceptedTerms = false;
  bool _actionLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshContract());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshContract();
    }
  }

  void _refreshContract() {
    if (mounted && !_actionLoading) {
      ref.invalidate(tenantContractProvider);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractAsync = ref.watch(tenantContractProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hợp đồng'),
        backgroundColor: colors.surfaceContainerLowest,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(tenantContractProvider.future),
        child: contractAsync.when(
          loading: () =>
              const PageLoading(message: 'Đang tải thông tin hợp đồng...'),
          error: (error, _) => ErrorState(
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(tenantContractProvider),
          ),
          data: (contract) => contract == null
              ? const EmptyState(
                  icon: Icons.description_outlined,
                  title: 'Chưa có hợp đồng',
                  subtitle:
                      'Khi quản lý gửi hợp đồng mới, bạn có thể xem và xác nhận tại đây.',
                )
              : _buildContract(context, contract),
        ),
      ),
    );
  }

  Widget _buildContract(BuildContext context, RentalContract contract) {
    final colors = Theme.of(context).colorScheme;
    final startDate = DateFormatter.tryParse(contract.startDate);
    final endDate = DateFormatter.tryParse(contract.endDate);
    final daysLeft = endDate?.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContractHeader(contract: contract, daysLeft: daysLeft),
          const SizedBox(height: 24),
          Text('Thông tin hợp đồng', style: AppTextStyles.titleLg),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.tag_outlined,
                  label: 'Mã hợp đồng',
                  value: contract.contractNumber ?? 'Chưa cập nhật',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'Phòng thuê',
                  value: 'Phòng ${contract.roomNumber ?? '--'}',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Thời hạn',
                  value:
                      '${DateFormatter.format(startDate)} - ${DateFormatter.format(endDate)}',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Tiền thuê/tháng',
                  value: CurrencyFormatter.format(contract.monthlyRent),
                  valueColor: colors.primary,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.savings_outlined,
                  label: 'Tiền đặt cọc',
                  value: CurrencyFormatter.format(contract.deposit),
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.event_repeat_outlined,
                  label: 'Ngày thanh toán',
                  value: 'Ngày ${contract.monthlyDueDay ?? 5} hàng tháng',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.people_outline,
                  label: 'Số người đang ở',
                  value:
                      '${contract.currentOccupantCount ?? 1}/${contract.maxOccupants ?? '--'} người',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Điều khoản hợp đồng', style: AppTextStyles.titleLg),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contract.notes?.trim().isNotEmpty == true
                        ? contract.notes!.trim()
                        : 'Hợp đồng chưa có điều khoản bổ sung. Các quyền và nghĩa vụ thực hiện theo nội dung đã thống nhất với quản lý.',
                    style: AppTextStyles.bodyMd.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          if (contract.isPendingConfirmation) ...[
            const SizedBox(height: 24),
            _buildConfirmationSection(contract),
          ],
          if (contract.status?.toUpperCase() == 'REJECTED') ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lý do từ chối', style: AppTextStyles.titleSm),
                  const SizedBox(height: 6),
                  Text(
                    contract.tenantRejectionReason ?? 'Không có lý do',
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
          ],
          if (contract.isActive &&
              daysLeft != null &&
              daysLeft >= 0 &&
              daysLeft <= 30) ...[
            const SizedBox(height: 20),
            _ExpiryNotice(daysLeft: daysLeft),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationSection(RentalContract contract) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Xác nhận hợp đồng',
                  style: AppTextStyles.titleMd.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy kiểm tra kỹ thông tin trước khi xác nhận. Sau khi xác nhận, hợp đồng sẽ có hiệu lực và phòng được ghi nhận là đã thuê.',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: _acceptedTerms,
              onChanged: _actionLoading
                  ? null
                  : (value) => setState(() => _acceptedTerms = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tôi đã đọc, hiểu và đồng ý với nội dung hợp đồng.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _actionLoading
                      ? null
                      : () => _rejectContract(contract),
                  icon: const Icon(Icons.close),
                  label: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: !_acceptedTerms || _actionLoading
                      ? null
                      : () => _confirmContract(contract),
                  icon: _actionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Xác nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmContract(RentalContract contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hợp đồng?'),
        content: const Text(
          'Hợp đồng sẽ bắt đầu có hiệu lực sau khi bạn xác nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Xem lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đồng ý xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || contract.id == null) return;

    await _runAction(
      () => TenantRepository.instance.confirmContract(contract.id!),
      successMessage: 'Đã xác nhận hợp đồng thành công.',
    );
  }

  Future<void> _rejectContract(RentalContract contract) async {
    if (contract.id == null) return;
    final reason = await _showRejectionDialog();
    if (reason == null) return;

    await _runAction(
      () => TenantRepository.instance.rejectContract(
        contractId: contract.id!,
        reason: reason,
      ),
      successMessage: 'Đã gửi phản hồi từ chối hợp đồng.',
    );
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối hợp đồng'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Lý do từ chối',
              hintText: 'Ví dụ: Thông tin tiền cọc chưa đúng...',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do từ chối'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Gửi từ chối'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _runAction(
    Future<RentalContract> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _actionLoading = true);
    try {
      await action();
      ref.invalidate(tenantContractProvider);
      ref.invalidate(tenantDashboardProvider);
      if (mounted) {
        setState(() => _acceptedTerms = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(error)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is NetworkException) return error.message;
    return 'Không thể xử lý hợp đồng. Vui lòng thử lại.';
  }
}

class _ContractHeader extends StatelessWidget {
  final RentalContract contract;
  final int? daysLeft;

  const _ContractHeader({required this.contract, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = contract.isPendingConfirmation;
    final headerColor = pending ? colors.tertiaryContainer : colors.primary;
    final foreground = pending ? colors.onTertiaryContainer : colors.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pending ? 'Hợp đồng mới' : 'Hợp đồng thuê phòng',
                  style: AppTextStyles.titleMd.copyWith(color: foreground),
                ),
              ),
              StatusChip(status: contract.status ?? 'UNKNOWN'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Phòng ${contract.roomNumber ?? '--'}',
            style: AppTextStyles.displaySm.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(contract.monthlyRent)} / tháng',
            style: AppTextStyles.titleMd.copyWith(color: foreground),
          ),
          if (pending) ...[
            const SizedBox(height: 12),
            Text(
              'Quản lý đang chờ bạn kiểm tra và xác nhận hợp đồng này.',
              style: AppTextStyles.bodyMd.copyWith(color: foreground),
            ),
          ] else if (contract.isActive && daysLeft != null) ...[
            const SizedBox(height: 12),
            Text(
              daysLeft! >= 0
                  ? 'Còn $daysLeft ngày đến hạn hợp đồng'
                  : 'Hợp đồng đã quá ngày kết thúc',
              style: AppTextStyles.bodyMd.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.titleSm.copyWith(
              color: valueColor ?? colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpiryNotice extends StatelessWidget {
  final int daysLeft;

  const _ExpiryNotice({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hợp đồng sẽ hết hạn sau $daysLeft ngày. Vui lòng liên hệ quản lý nếu cần gia hạn.',
              style: AppTextStyles.bodyMd,
            ),
          ),
        ],
      ),
    );
  }
}
