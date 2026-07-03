import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_models.dart';
import '../../data/repositories/tenant_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';

final tenantInvoiceDetailProvider =
    FutureProvider.family<InvoiceDetail, int>((ref, invoiceId) async {
  return TenantRepository.instance.invoiceDetail(invoiceId);
});

class TenantInvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;

  const TenantInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tenantInvoiceDetailProvider(invoiceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: detailAsync.when(
        data: (detail) {
          final invoice = detail.invoice;
          final items = detail.items;
          final payments = detail.payments;

          if (invoice == null) {
            return const EmptyState(
              title: 'Không tìm thấy thông tin hóa đơn',
              icon: Icons.receipt_long_outlined,
            );
          }

          final isOverdue = invoice.status?.toUpperCase() == 'OVERDUE';
          final remaining = invoice.remainingAmount ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header Card ───────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mã HĐ: ${invoice.invoiceNumber ?? '—'}',
                                style: AppTextStyles.titleSm.copyWith(color: AppColors.outline),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tháng ${invoice.billingMonth}/${invoice.billingYear}',
                                style: AppTextStyles.headlineSm,
                              ),
                            ],
                          ),
                          StatusChip(status: invoice.status ?? 'DRAFT'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Phòng: ${invoice.roomNumber ?? '—'}',
                        style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Khách thuê: ${invoice.tenantName ?? '—'}',
                        style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Amount Summary Card ───────────────────
                AppCard(
                  backgroundColor: AppColors.surfaceContainerLow,
                  child: Column(
                    children: [
                      _buildSummaryRow('Tổng số tiền', CurrencyFormatter.format(invoice.totalAmount), isBold: true, valueColor: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Đã thanh toán', CurrencyFormatter.format(invoice.paidAmount), valueColor: AppColors.success),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Còn lại cần đóng',
                        CurrencyFormatter.format(remaining),
                        isBold: true,
                        valueColor: remaining > 0 ? (isOverdue ? AppColors.danger : Theme.of(context).colorScheme.primaryContainer) : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.outline),
                          const SizedBox(width: 8),
                          Text(
                            'Hạn thanh toán: ${DateFormatter.format(DateFormatter.tryParse(invoice.dueDate))}',
                            style: AppTextStyles.bodySm.copyWith(
                              color: isOverdue ? AppColors.danger : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Breakdown Items ───────────────────────
                Text('Chi tiết các khoản mục', style: AppTextStyles.titleMd),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description ?? 'Dịch vụ', style: AppTextStyles.titleSm),
                                  if (item.quantity != null && item.unitPrice != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Số lượng: ${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                                      style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.amount),
                              style: AppTextStyles.titleSm,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Payment History ────────────────────────
                if (payments.isNotEmpty) ...[
                  Text('Lịch sử thanh toán', style: AppTextStyles.titleMd),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final p = payments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatter.formatDateTime(DateFormatter.tryParse(p.paymentDate)),
                                    style: AppTextStyles.titleSm,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.methodLabel,
                                    style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(p.amount),
                                    style: AppTextStyles.titleSm.copyWith(color: AppColors.success),
                                  ),
                                  const SizedBox(height: 2),
                                  StatusChip(status: p.status ?? 'CONFIRMED', fontSize: 10),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ─── Payment Instructions ───────────────────
                if (remaining > 0) ...[
                  Text('Hướng dẫn thanh toán', style: AppTextStyles.titleMd),
                  const SizedBox(height: 12),
                  AppCard(
                    backgroundColor: AppColors.warningLight.withAlpha(120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.tertiary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Chuyển khoản ngân hàng',
                              style: AppTextStyles.titleSm.copyWith(color: AppColors.tertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Vui lòng thực hiện chuyển khoản với nội dung:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBankInfo(context, 'Ngân hàng', 'Ngân hàng Techcombank (TCB)'),
                              _buildBankInfo(context, 'Chủ tài khoản', 'NGUYEN VAN A'),
                              _buildBankInfo(context, 'Số tài khoản', '19035678901011'),
                              _buildBankInfo(context, 'Nội dung CK', 'Lumina ${invoice.roomNumber} T${invoice.billingMonth}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '*Sau khi chuyển khoản, vui lòng thông báo cho quản lý toà nhà để xác nhận thanh toán thủ công.',
                          style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── Contact Admin Button ──────────────────
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liên hệ quản lý: 0987654321')),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Liên hệ quản lý xác nhận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const PageLoading(message: 'Đang tải chi tiết hóa đơn...'),
        error: (err, stack) => ErrorState(
          message: 'Không thể tải chi tiết hóa đơn',
          onRetry: () => ref.invalidate(tenantInvoiceDetailProvider(invoiceId)),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    final style = isBold ? AppTextStyles.titleMd : AppTextStyles.bodyLg;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: style.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
