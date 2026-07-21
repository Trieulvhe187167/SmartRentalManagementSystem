import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

class AdminRevenueReportScreen extends ConsumerStatefulWidget {
  const AdminRevenueReportScreen({super.key});

  @override
  ConsumerState<AdminRevenueReportScreen> createState() =>
      _AdminRevenueReportScreenState();
}

class _AdminRevenueReportScreenState
    extends ConsumerState<AdminRevenueReportScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(
      adminRevenueSummaryProvider(_selectedYear),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Báo cáo doanh thu')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminRevenueSummaryProvider(_selectedYear));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Doanh thu năm $_selectedYear',
                      style: AppTextStyles.titleLg,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 3 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              revenueAsync.when(
                data: (months) {
                  final billed = List<double>.filled(12, 0);
                  final collected = List<double>.filled(12, 0);
                  final debt = List<double>.filled(12, 0);
                  var invoiceCount = 0;
                  var paidInvoiceCount = 0;
                  for (final data in months) {
                    if (data.month < 1 || data.month > 12) continue;
                    final index = data.month - 1;
                    billed[index] = data.totalRevenue;
                    collected[index] = data.collectedRevenue;
                    debt[index] = data.debtAmount;
                    invoiceCount += data.invoiceCount;
                    paidInvoiceCount += data.paidInvoiceCount;
                  }

                  final totalBilled = billed.fold<double>(0, (a, b) => a + b);
                  final totalCollected = collected.fold<double>(
                    0,
                    (a, b) => a + b,
                  );
                  final totalDebt = debt.fold<double>(0, (a, b) => a + b);
                  final collectionRate = totalBilled == 0
                      ? 0.0
                      : totalCollected / totalBilled * 100;
                  final maxValue = billed.fold<double>(0, (current, value) {
                    return value > current ? value : current;
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doanh thu và công nợ theo tháng',
                              style: AppTextStyles.titleSm,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildLegend(
                                  context,
                                  'Đã lập hóa đơn',
                                  Theme.of(context).colorScheme.primary,
                                ),
                                _buildLegend(
                                  context,
                                  'Đã thu',
                                  AppColors.success,
                                ),
                                _buildLegend(
                                  context,
                                  'Còn nợ',
                                  AppColors.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 260,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxValue == 0 ? 1 : maxValue * 1.2,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) =>
                                          AppColors.inverseSurface,
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                        const labels = [
                                          'Đã lập',
                                          'Đã thu',
                                          'Còn nợ',
                                        ];
                                        return BarTooltipItem(
                                          '${labels[rodIndex]} T${group.x + 1}\n${CurrencyFormatter.compact(rod.toY)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) => Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'T${value.toInt() + 1}',
                                            style: AppTextStyles.labelSm,
                                          ),
                                        ),
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 48,
                                        getTitlesWidget: (value, _) => Text(
                                          CurrencyFormatter.compact(value),
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      strokeWidth: 0.6,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(12, (index) {
                                    return BarChartGroupData(
                                      x: index,
                                      barsSpace: 2,
                                      barRods: [
                                        _bar(
                                          billed[index],
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                        _bar(
                                          collected[index],
                                          AppColors.success,
                                        ),
                                        _bar(debt[index], AppColors.warning),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Thống kê tổng hợp', style: AppTextStyles.titleLg),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildReportStatRow(
                              'Tổng giá trị hóa đơn',
                              CurrencyFormatter.format(totalBilled),
                            ),
                            const Divider(height: 1),
                            _buildReportStatRow(
                              'Doanh thu thực nhận',
                              CurrencyFormatter.format(totalCollected),
                              valueColor: AppColors.success,
                            ),
                            const Divider(height: 1),
                            _buildReportStatRow(
                              'Công nợ còn lại',
                              CurrencyFormatter.format(totalDebt),
                              valueColor: AppColors.warning,
                            ),
                            const Divider(height: 1),
                            _buildReportStatRow(
                              'Hóa đơn đã thanh toán',
                              '$paidInvoiceCount/$invoiceCount hóa đơn',
                            ),
                            const Divider(height: 1),
                            _buildReportStatRow(
                              'Tỷ lệ thu tiền',
                              '${collectionRate.toStringAsFixed(1)}%',
                              valueColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const PageLoading(
                  message: 'Đang tải báo cáo doanh thu...',
                ),
                error: (error, _) => ErrorState(
                  message: 'Không thể tải báo cáo doanh thu: $error',
                  onRetry: () => ref.invalidate(
                    adminRevenueSummaryProvider(_selectedYear),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  BarChartRodData _bar(double value, Color color) {
    return BarChartRodData(
      toY: value,
      color: color,
      width: 7,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    );
  }

  Widget _buildLegend(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildReportStatRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
