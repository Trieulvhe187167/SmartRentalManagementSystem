import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_models.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'tenant_controller.dart';

class TenantInvoiceListScreen extends ConsumerStatefulWidget {
  const TenantInvoiceListScreen({super.key});

  @override
  ConsumerState<TenantInvoiceListScreen> createState() =>
      _TenantInvoiceListScreenState();
}

class _TenantInvoiceListScreenState
    extends ConsumerState<TenantInvoiceListScreen> {
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
      ref.read(tenantInvoicesProvider.notifier).fetchInvoices();
    }
  }

  List<Invoice> _filterInvoices(List<Invoice> items) {
    final visibleItems = items
        .where((invoice) => invoice.isVisibleToTenant)
        .toList();
    if (_selectedStatus == 'ALL') return visibleItems;
    if (_selectedStatus == 'UNPAID') {
      return visibleItems.where((invoice) {
        final status = invoice.status?.toUpperCase();
        return status == 'ISSUED' || status == 'PARTIALLY_PAID';
      }).toList();
    }
    return visibleItems
        .where(
          (invoice) => (invoice.status ?? '').toUpperCase() == _selectedStatus,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantInvoicesProvider);
    final dashboardAsync = ref.watch(tenantDashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Danh sách Hóa đơn'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
              .read(tenantInvoicesProvider.notifier)
              .fetchInvoices(refresh: true);
          ref.read(tenantDashboardProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ─── Thống kê dư nợ / Đã đóng ─────────────────────
            SliverToBoxAdapter(
              child: dashboardAsync.when(
                data: (dashboard) {
                  final debt = dashboard.totalDebt ?? 0.0;
                  final currentInvoice = dashboard.currentInvoice;
                  final paidAmount = currentInvoice != null
                      ? (currentInvoice.paidAmount ?? 0.0)
                      : 0.0;

                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tổng nợ hiện tại',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(debt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hóa đơn gần nhất đã thanh toán',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(paidAmount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CardShimmer(height: 80),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // ─── Filter Chips Row ────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('ALL', 'Tất cả'),
                    const SizedBox(width: 8),
                    _buildFilterChip('UNPAID', 'Chưa thanh toán'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PAID', 'Đã thanh toán'),
                    const SizedBox(width: 8),
                    _buildFilterChip('OVERDUE', 'Quá hạn'),
                  ],
                ),
              ),
            ),

            // ─── Main Content ───────────────────────────────
            if (state.isLoading && state.items.isEmpty)
              const SliverFillRemaining(
                child: PageLoading(message: 'Đang tải hóa đơn...'),
              )
            else if (state.error != null && state.items.isEmpty)
              SliverFillRemaining(
                child: ErrorState(
                  message: 'Không thể tải hóa đơn: ${state.error}',
                  onRetry: () => ref
                      .read(tenantInvoicesProvider.notifier)
                      .fetchInvoices(refresh: true),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final filteredList = _filterInvoices(state.items);
                      if (filteredList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: EmptyState(
                            title: 'Không tìm thấy hóa đơn nào',
                            icon: Icons.receipt_long_outlined,
                          ),
                        );
                      }
                      if (index >= filteredList.length) {
                        return state.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final inv = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () {
                            if (inv.id != null) {
                              context.push(AppRoutes.invoiceDetail(inv.id!));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Hóa đơn tháng ${inv.billingMonth}/${inv.billingYear}',
                                      style: AppTextStyles.titleMd.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    StatusChip(status: inv.status ?? 'UNPAID'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Mã HĐ: ${inv.invoiceNumber ?? "—"}',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hạn thanh toán',
                                          style: AppTextStyles.bodySm.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormatter.format(
                                            DateFormatter.tryParse(inv.dueDate),
                                          ),
                                          style: AppTextStyles.bodyMd.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Tổng tiền',
                                          style: AppTextStyles.bodySm.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(
                                            inv.totalAmount,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
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
                    },
                    childCount: _filterInvoices(state.items).isEmpty
                        ? 1
                        : _filterInvoices(state.items).length + 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedStatus = status;
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
