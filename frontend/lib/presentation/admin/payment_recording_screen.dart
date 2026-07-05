import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/payment_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';

class AdminPaymentRecordingScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  final double remainingAmount;
  final String? tenantName;
  final String? roomNumber;
  final int? billingMonth;
  final int? billingYear;

  const AdminPaymentRecordingScreen({
    super.key,
    required this.invoiceId,
    required this.remainingAmount,
    this.tenantName,
    this.roomNumber,
    this.billingMonth,
    this.billingYear,
  });

  @override
  ConsumerState<AdminPaymentRecordingScreen> createState() => _AdminPaymentRecordingScreenState();
}

class _AdminPaymentRecordingScreenState extends ConsumerState<AdminPaymentRecordingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _paymentMethod = 'BANK_TRANSFER';
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;
  int _quickPercent = 100;

  @override
  void initState() {
    super.initState();
    // Đặt số tiền mặc định là số tiền còn lại
    _amountCtrl.text = widget.remainingAmount.toInt().toString();
    _amountCtrl.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Reset quick percent chip if the manual input does not match the quick values
    final currentAmount = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    int matchesPercent = 0;
    if (currentAmount == widget.remainingAmount) {
      matchesPercent = 100;
    } else if (currentAmount == (widget.remainingAmount * 0.5).toInt()) {
      matchesPercent = 50;
    } else if (currentAmount == (widget.remainingAmount * 0.25).toInt()) {
      matchesPercent = 25;
    }
    if (matchesPercent != _quickPercent) {
      setState(() {
        _quickPercent = matchesPercent;
      });
    }
  }

  void _applyQuickPercent(int percent) {
    setState(() {
      _quickPercent = percent;
      final targetAmount = (widget.remainingAmount * (percent / 100)).toInt();
      _amountCtrl.text = targetAmount.toString();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      final req = PaymentCreateRequest(
        amount: amount,
        method: _paymentMethod,
        paymentDate: _paymentDate.toIso8601String().substring(0, 10),
        notes: _noteCtrl.text.trim().isEmpty ? 'Ghi nhận thanh toán' : _noteCtrl.text.trim(),
      );

      await AdminRepository.instance.recordPayment(widget.invoiceId, req);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghi nhận thanh toán thành công'), backgroundColor: AppColors.success),
        );
        context.pop(true);
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
    final enteredAmount = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final remainingAfter = widget.remainingAmount - enteredAmount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ghi nhận Thanh toán'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header Info Card ───────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      Theme.of(context).colorScheme.primary.withOpacity(0.03),
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Hóa đơn tháng ${widget.billingMonth ?? ""}/${widget.billingYear ?? ""}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const StatusChip(status: 'UNPAID'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Khách thuê', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(widget.tenantName ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phòng', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(widget.roomNumber ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tổng hóa đơn', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(CurrencyFormatter.format(widget.remainingAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Còn lại cần thu', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(widget.remainingAmount),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Input Form Card ────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payments, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text('Thông tin thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const Divider(height: 24),

                            // Field: Số tiền
                            const Text('Số tiền thanh toán *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                suffixText: '₫',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                helperText: 'Số tiền tối đa: ${CurrencyFormatter.format(widget.remainingAmount)}',
                                helperStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tiền';
                                final parsed = double.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                                if (parsed == null || parsed <= 0) return 'Số tiền không hợp lệ';
                                if (parsed > widget.remainingAmount) return 'Số tiền vượt quá số nợ cần thu';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Quick Amount Percent Chips
                            Row(
                              children: [
                                _quickPercentChip(25, '25% (nhỏ)'),
                                const SizedBox(width: 8),
                                _quickPercentChip(50, '50% (nửa)'),
                                const SizedBox(width: 8),
                                _quickPercentChip(100, '100% (đủ)'),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Field: Phương thức thanh toán
                            const Text('Phương thức thanh toán *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _paymentMethodCard('BANK_TRANSFER', Icons.account_balance, 'Chuyển khoản')),
                                const SizedBox(width: 8),
                                Expanded(child: _paymentMethodCard('CASH', Icons.payments, 'Tiền mặt')),
                                const SizedBox(width: 8),
                                Expanded(child: _paymentMethodCard('OTHER', Icons.qr_code, 'Khác')),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Field: Ngày thanh toán
                            const Text('Ngày thanh toán *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                                      DateFormatter.format(DateFormatter.tryParse(_paymentDate.toIso8601String())),
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                    ),
                                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Field: Ghi chú
                            const Text('Ghi chú (tùy chọn)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Nhập ghi chú thanh toán (ví dụ: Chuyển khoản đóng tiền phòng tháng 6...)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Tóm tắt sau thanh toán
                    AppCard(
                      child: Container(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Tóm tắt sau khi ghi nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                            const Divider(height: 24),
                            _summaryRow('Số tiền ghi nhận', enteredAmount, isValueGreen: true),
                            const SizedBox(height: 8),
                            _summaryRow('Còn lại sau thanh toán', remainingAfter, isValueGreen: remainingAfter <= 0),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Trạng thái hóa đơn mới', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                StatusChip(status: remainingAfter <= 0 ? 'PAID' : 'PARTIAL'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Xác nhận thanh toán', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickPercentChip(int percent, String label) {
    final isSelected = _quickPercent == percent;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) _applyQuickPercent(percent);
      },
    );
  }

  Widget _paymentMethodCard(String method, IconData icon, String label) {
    final isSelected = _paymentMethod == method;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isValueGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isValueGreen ? Colors.green : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
