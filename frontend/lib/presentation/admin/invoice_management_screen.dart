import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

final adminInvoiceDetailProvider =
    FutureProvider.family<InvoiceDetail, int>((ref, invoiceId) {
  return AdminRepository.instance.invoiceDetail(invoiceId);
});

class AdminInvoiceManagementScreen extends ConsumerStatefulWidget {
  const AdminInvoiceManagementScreen({super.key});

  @override
  ConsumerState<AdminInvoiceManagementScreen> createState() => _AdminInvoiceManagementScreenState();
}

class _AdminInvoiceManagementScreenState extends ConsumerState<AdminInvoiceManagementScreen> {
  final _scrollController = ScrollController();
  final _filterScrollController = ScrollController();
  String _selectedStatus = 'ALL';
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminInvoicesProvider.notifier).fetchInvoices();
    }
  }

  void _applyFilters() {
    ref.read(adminInvoicesProvider.notifier).updateFilters(
          _selectedStatus,
          _selectedMonth,
          _selectedYear,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInvoicesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, size: 24),
            onPressed: () => _showGenerateMonthlyDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(adminInvoicesProvider.notifier).fetchInvoices(refresh: true);
        },
        child: Column(
          children: [
            // ─── Filter & Stats Section ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedMonth,
                          decoration: const InputDecoration(labelText: 'Tháng'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tất cả')),
                            ...List.generate(12, (i) {
                              return DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'));
                            }),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedMonth = v);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedYear,
                          decoration: const InputDecoration(labelText: 'Năm'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tất cả')),
                            DropdownMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}')),
                            DropdownMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}')),
                            DropdownMenuItem(value: DateTime.now().year + 1, child: Text('${DateTime.now().year + 1}')),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedYear = v);
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: const {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: ListView(
                        controller: _filterScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildFilterChip('ALL', 'Tất cả'),
                          const SizedBox(width: 8),
                          _buildFilterChip('DRAFT', 'Nháp'),
                          const SizedBox(width: 8),
                          _buildFilterChip('ISSUED', 'Phát hành'),
                          const SizedBox(width: 8),
                          _buildFilterChip('PARTIALLY_PAID', 'Thanh toán một phần'),
                          const SizedBox(width: 8),
                          _buildFilterChip('DEBT', 'Công nợ'),
                          const SizedBox(width: 8),
                          _buildFilterChip('PAID', 'Đã thu'),
                          const SizedBox(width: 8),
                          _buildFilterChip('OVERDUE', 'Quá hạn'),
                          const SizedBox(width: 8),
                          _buildFilterChip('CANCELLED', 'Hủy'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── List of Invoices ────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (context, index) => const CardShimmer(height: 120),
                    )
                  : state.error != null
                      ? ErrorState(
                          message: 'Lỗi tải hóa đơn: ${state.error}',
                          onRetry: () => ref.read(adminInvoicesProvider.notifier).fetchInvoices(refresh: true),
                        )
                      : state.items.isEmpty
                          ? const EmptyState(
                              title: 'Không tìm thấy hóa đơn nào',
                              subtitle: 'Chọn lọc khác hoặc bấm nút ở góc phải để chạy hóa đơn tự động',
                              icon: Icons.receipt_long_outlined,
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
                                return _buildInvoiceCard(context, item);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.bolt),
        label: const Text('Chạy hóa đơn tháng'),
        onPressed: () => _showGenerateMonthlyDialog(context),
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
          _applyFilters();
        }
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    final debt = invoice.remainingAmount ?? 0.0;
    final isOverdue = invoice.status?.toUpperCase() == 'OVERDUE';

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
              'Phòng ${invoice.roomNumber}',
              style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
            ),
            StatusChip(status: invoice.status ?? 'DRAFT'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Khách: ${invoice.tenantName} · Tháng ${invoice.billingMonth}/${invoice.billingYear}',
              style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Tổng tiền: ${CurrencyFormatter.format(invoice.totalAmount)}',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
            ),
            if (debt > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Còn nợ: ${CurrencyFormatter.format(debt)}',
                style: AppTextStyles.bodySm.copyWith(
                  color: isOverdue ? AppColors.danger : AppColors.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showInvoiceDetailSheet(context, invoice.id!),
      ),
    );
  }

  void _showInvoiceDetailSheet(BuildContext context, int invoiceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _InvoiceDetailView(
          invoiceId: invoiceId,
          onRefreshList: () => ref.read(adminInvoicesProvider.notifier).fetchInvoices(refresh: true),
        );
      },
    );
  }

  void _showGenerateMonthlyDialog(BuildContext context) {
    final screenContext = context;
    int month = DateTime.now().month;
    int year = DateTime.now().year;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Chạy hóa đơn tự động'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chạy hóa đơn tự động cho toàn bộ phòng hoạt động trong tháng này:'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: month,
                      decoration: const InputDecoration(labelText: 'Tháng'),
                      items: List.generate(12, (i) {
                        return DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'));
                      }),
                      onChanged: (v) {
                        if (v != null) month = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: year,
                      decoration: const InputDecoration(labelText: 'Năm'),
                      items: [
                        DropdownMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}')),
                        DropdownMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}')),
                        DropdownMenuItem(value: DateTime.now().year + 1, child: Text('${DateTime.now().year + 1}')),
                      ],
                      onChanged: (v) {
                        if (v != null) year = v;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final error = await ref.read(adminInvoicesProvider.notifier).generateMonthly(month, year);
                if (screenContext.mounted) {
                  if (error != null) {
                    if (error.contains('Thiếu chỉ số')) {
                      _showMissingMeterReadingDialog(screenContext, error);
                    } else {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: AppColors.error),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(content: Text('Khởi tạo hóa đơn thành công!'), backgroundColor: AppColors.success),
                    );
                  }
                }
              },
              child: const Text('Khởi chạy'),
            ),
          ],
        );
      },
    );
  }

  void _showMissingMeterReadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Thiếu chỉ số điện nước'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(AppRoutes.adminMeterReadings);
              },
              child: const Text('Nhập chỉ số'),
            ),
          ],
        );
      },
    );
  }
}

class _InvoiceDetailView extends ConsumerStatefulWidget {
  final int invoiceId;
  final VoidCallback onRefreshList;

  const _InvoiceDetailView({required this.invoiceId, required this.onRefreshList});

  @override
  ConsumerState<_InvoiceDetailView> createState() => _InvoiceDetailViewState();
}

class _InvoiceDetailViewState extends ConsumerState<_InvoiceDetailView> {
  bool _actionLoading = false;

  void _refreshData() {
    ref.invalidate(adminInvoiceDetailProvider(widget.invoiceId));
    widget.onRefreshList();
  }

  Future<void> _recordPayment(Invoice invoice) async {
    final result = await context.push<bool>(
      AppRoutes.adminPaymentRecording,
      extra: {
        'invoiceId': widget.invoiceId,
        'remainingAmount': invoice.remainingAmount ?? 0.0,
        'tenantName': invoice.tenantName,
        'roomNumber': invoice.roomNumber,
        'billingMonth': invoice.billingMonth,
        'billingYear': invoice.billingYear,
      },
    );
    if (result == true && mounted) {
      _refreshData();
    }
  }

  Future<void> _issueInvoice(Invoice invoice) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final currentDueDate = DateTime.tryParse(invoice.dueDate ?? '');
    var dueDate = currentDueDate == null || currentDueDate.isBefore(today)
        ? today.add(const Duration(days: 7))
        : DateUtils.dateOnly(currentDueDate);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Phát hành hóa đơn'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn hạn thanh toán trước khi phát hành.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: today,
                        lastDate: today.add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormatter.format(dueDate)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Phát hành'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    final error = await ref.read(adminInvoicesProvider.notifier).issueInvoice(
          widget.invoiceId,
          dueDate.toIso8601String().substring(0, 10),
        );
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (error != null) {
      _showError(error);
      return;
    }
    _refreshData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã phát hành hóa đơn'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _addAdjustment() async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm khoản điều chỉnh'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung điều chỉnh',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập nội dung'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VND)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount == 0) {
                    return 'Số tiền phải khác 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _actionLoading = true);
      try {
        await AdminRepository.instance.addInvoiceAdjustment(
          widget.invoiceId,
          InvoiceAdjustmentRequest(
            description: descriptionController.text.trim(),
            amount: double.parse(amountController.text.trim()),
            note: noteController.text.trim(),
          ),
        );
        if (mounted) {
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm khoản điều chỉnh'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (error) {
        if (mounted) _showError(error.toString());
      } finally {
        if (mounted) setState(() => _actionLoading = false);
      }
    }
    descriptionController.dispose();
    amountController.dispose();
    noteController.dispose();
  }

  Future<void> _cancelInvoice() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy hóa đơn'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Lý do hủy',
              hintText: 'Nhập lý do để lưu lịch sử đối soát',
            ),
            maxLines: 3,
            maxLength: 500,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do hủy'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _actionLoading = true);
      final error = await ref.read(adminInvoicesProvider.notifier).cancelInvoice(
            widget.invoiceId,
            reasonController.text.trim(),
          );
      if (mounted) {
        setState(() => _actionLoading = false);
        if (error != null) {
          _showError(error);
        } else {
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy hóa đơn'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
    reasonController.dispose();
  }

  Future<void> _cancelPayment(int paymentId) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy giao dịch thanh toán'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Lý do hủy'),
            maxLines: 3,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do hủy'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Hủy giao dịch'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _actionLoading = true);
      try {
        await AdminRepository.instance.cancelPayment(
          paymentId,
          reasonController.text.trim(),
        );
        if (mounted) {
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy giao dịch và cập nhật lại công nợ'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (error) {
        if (mounted) _showError(error.toString());
      } finally {
        if (mounted) setState(() => _actionLoading = false);
      }
    }
    reasonController.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminInvoiceDetailProvider(widget.invoiceId));

    return detailAsync.when(
      data: (detail) {
        final invoice = detail.invoice!;
        final items = detail.items;
        final payments = detail.payments;
        final remaining = invoice.remainingAmount ?? 0.0;

        final isDraft = invoice.status?.toUpperCase() == 'DRAFT';
        final isIssued = const {
          'ISSUED',
          'PARTIALLY_PAID',
          'OVERDUE',
        }.contains(invoice.status?.toUpperCase());
        final hasConfirmedPayments = payments.any(
          (payment) => payment.status?.toUpperCase() == 'CONFIRMED',
        );
        final canCancelInvoice =
            invoice.status?.toUpperCase() != 'CANCELLED' &&
            invoice.status?.toUpperCase() != 'PAID' &&
            !hasConfirmedPayments;

        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
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
                      Text('Phòng ${invoice.roomNumber}', style: AppTextStyles.headlineSm),
                      StatusChip(status: invoice.status ?? 'DRAFT'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  _buildDetailRow('Tổng tiền hóa đơn', CurrencyFormatter.format(invoice.totalAmount), color: Theme.of(context).colorScheme.primaryContainer),
                  const SizedBox(height: 8),
                  _buildDetailRow('Đã đóng', CurrencyFormatter.format(invoice.paidAmount), color: AppColors.success),
                  const SizedBox(height: 8),
                  _buildDetailRow('Còn nợ', CurrencyFormatter.format(remaining), color: remaining > 0 ? AppColors.danger : Theme.of(context).colorScheme.onSurface),

                  const SizedBox(height: 20),
                  Text('Danh sách chi phí:', style: AppTextStyles.titleSm),
                  const SizedBox(height: 12),
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.description} ${item.quantity != null ? '(x${item.quantity}${item.unit == null ? '' : ' ${item.unit}'})' : ''}',
                              style: AppTextStyles.bodyMd,
                            ),
                          ),
                          Text(CurrencyFormatter.format(item.amount), style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  if (payments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Lịch sử thanh toán', style: AppTextStyles.titleSm),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Column(
                        children: payments.map((payment) {
                          final isConfirmed =
                              payment.status?.toUpperCase() == 'CONFIRMED';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: (isConfirmed
                                      ? AppColors.success
                                      : AppColors.outline)
                                  .withValues(alpha: 0.12),
                              child: Icon(
                                isConfirmed
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                color: isConfirmed
                                    ? AppColors.success
                                    : AppColors.outline,
                              ),
                            ),
                            title: Text(
                              CurrencyFormatter.format(payment.amount),
                              style: AppTextStyles.titleSm,
                            ),
                            subtitle: Text(
                              '${payment.methodLabel} · ${DateFormatter.format(DateFormatter.tryParse(payment.paymentDate))}',
                              style: AppTextStyles.bodySm,
                            ),
                            trailing: isConfirmed && payment.id != null
                                ? IconButton(
                                    tooltip: 'Hủy giao dịch sai',
                                    onPressed: _actionLoading
                                        ? null
                                        : () => _cancelPayment(payment.id!),
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: AppColors.danger,
                                    ),
                                  )
                                : StatusChip(
                                    status: payment.status ?? 'CANCELLED',
                                    fontSize: 10,
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Actions row
                  if (_actionLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (isDraft) ...[
                      OutlinedButton.icon(
                        onPressed: _addAdjustment,
                        icon: const Icon(Icons.playlist_add_outlined),
                        label: const Text('Thêm khoản điều chỉnh'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _issueInvoice(invoice),
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Phát hành hóa đơn'),
                      ),
                    ],
                    if (isIssued && remaining > 0) ...[
                      ElevatedButton.icon(
                        onPressed: () => _recordPayment(invoice),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Ghi nhận thanh toán'),
                      ),
                    ],
                    if (canCancelInvoice) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                        onPressed: _cancelInvoice,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Hủy hóa đơn này'),
                      ),
                    ],
                    if (hasConfirmedPayments &&
                        invoice.status?.toUpperCase() != 'PAID') ...[
                      const SizedBox(height: 12),
                      Text(
                        'Muốn hủy hóa đơn, hãy hủy các giao dịch thanh toán đã xác nhận trước.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.warning,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Không thể tải chi tiết: $e'))),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
