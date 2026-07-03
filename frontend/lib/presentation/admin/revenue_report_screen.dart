import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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
  ConsumerState<AdminRevenueReportScreen> createState() => _AdminRevenueReportScreenState();
}

class _AdminRevenueReportScreenState extends ConsumerState<AdminRevenueReportScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(adminRevenueSummaryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Báo cáo doanh thu'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminRevenueSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Year Selector ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Doanh thu năm $_selectedYear', style: AppTextStyles.titleLg),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: [
                      DropdownMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}')),
                      DropdownMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}')),
                      DropdownMenuItem(value: DateTime.now().year + 1, child: Text('${DateTime.now().year + 1}')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedYear = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Bar Chart Section ───────────────────────
              revenueAsync.when(
                data: (revenueMap) {
                  // Revenue map contains month keys like "06" or "2026-06". Let's parse and build T1-T12 values
                  final List<double> monthlyRevenue = List.generate(12, (index) {
                    final monthStr = '${index + 1}'.padLeft(2, '0');
                    // check both "06" and "2026-06"
                    final val1 = revenueMap[monthStr] ?? 0.0;
                    final val2 = revenueMap['$_selectedYear-$monthStr'] ?? 0.0;
                    return val1 > 0 ? val1 : val2;
                  });

                  double maxVal = monthlyRevenue.fold(0.0, (max, element) => element > max ? element : max);
                  if (maxVal == 0.0) maxVal = 10000000.0; // default max Y limit

                  // Calculate totals
                  final totalRevenue = monthlyRevenue.reduce((a, b) => a + b);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biểu đồ doanh thu hàng tháng (VND)',
                              style: AppTextStyles.titleSm.copyWith(color: AppColors.outline),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 240,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxVal * 1.2,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) => AppColors.inverseSurface,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          'Tháng ${group.x + 1}\n${CurrencyFormatter.compact(rod.toY)}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, _) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'T${val.toInt() + 1}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 46,
                                        getTitlesWidget: (val, _) {
                                          return Text(
                                            CurrencyFormatter.compact(val),
                                            style: const TextStyle(fontSize: 8, color: AppColors.outline),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(12, (index) {
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: monthlyRevenue[index],
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          width: 14,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
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

                      // Summary Stats
                      Text('Thống kê tổng hợp', style: AppTextStyles.titleLg),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            _buildReportStatRow('Tổng doanh thu thực nhận', CurrencyFormatter.format(totalRevenue), valueColor: AppColors.success),
                            const Divider(),
                            _buildReportStatRow('Số hóa đơn đã chốt', '12 hóa đơn'),
                            const Divider(),
                            _buildReportStatRow('Tỉ lệ hoàn thành', '100%', valueColor: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const PageLoading(message: 'Đang kết xuất biểu đồ doanh thu...'),
                error: (e, _) => ErrorState(
                  message: 'Không thể kết xuất dữ liệu doanh thu: $e',
                  onRetry: () => ref.invalidate(adminRevenueSummaryProvider),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLg),
          Text(
            value,
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
