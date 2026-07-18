import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/maintenance_models.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

class AdminMaintenanceManagementScreen extends ConsumerStatefulWidget {
  const AdminMaintenanceManagementScreen({super.key});

  @override
  ConsumerState<AdminMaintenanceManagementScreen> createState() => _AdminMaintenanceManagementScreenState();
}

class _AdminMaintenanceManagementScreenState extends ConsumerState<AdminMaintenanceManagementScreen> {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminMaintenanceProvider.notifier).fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminMaintenanceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('YĂªu cáº§u sá»­a chá»¯a'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(adminMaintenanceProvider.notifier).fetchRequests(refresh: true);
        },
        child: Column(
          children: [
            // â”€â”€â”€ Filter Status Chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              height: 60,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildFilterChip('ALL', 'Táº¥t cáº£'),
                  const SizedBox(width: 8),
                  _buildFilterChip('OPEN', 'Chá» tiáº¿p nháº­n'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RECEIVED', 'ÄĂ£ tiáº¿p nháº­n'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IN_PROGRESS', 'Äang sá»­a chá»¯a'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RESOLVED', 'ÄĂ£ hoĂ n thĂ nh'),
                  const SizedBox(width: 8),
                  _buildFilterChip('REJECTED', 'Tá»« chá»‘i'),
                ],
              ),
            ),

            // â”€â”€â”€ Requests list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (context, index) => const CardShimmer(height: 100),
                    )
                  : state.error != null
                      ? ErrorState(
                          message: 'Lá»—i táº£i yĂªu cáº§u: ${state.error}',
                          onRetry: () => ref.read(adminMaintenanceProvider.notifier).fetchRequests(refresh: true),
                        )
                      : state.items.isEmpty
                          ? const EmptyState(
                              title: 'KhĂ´ng cĂ³ yĂªu cáº§u sá»­a chá»¯a nĂ o',
                              subtitle: 'ChÆ°a cĂ³ khĂ¡ch thuĂª nĂ o gá»­i yĂªu cáº§u báº£o trĂ¬',
                              icon: Icons.build_outlined,
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
                                return _buildMaintenanceCard(context, item);
                              },
                            ),
            ),
          ],
        ),
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
          ref.read(adminMaintenanceProvider.notifier).updateStatus(value);
        }
      },
    );
  }

  Widget _buildMaintenanceCard(BuildContext context, MaintenanceRequest item) {
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
              'PhĂ²ng ${item.roomNumber ?? 'â€”'}',
              style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
            ),
            StatusChip(status: item.status ?? 'OPEN'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Sá»± cá»‘: ${item.title}',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'KhĂ¡ch: ${item.tenantName} Â· ${DateFormatter.format(DateFormatter.tryParse(item.requestDate))}',
              style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            PriorityChip(priority: item.priority ?? 'MEDIUM'),
          ],
        ),
        onTap: item.id == null
            ? null
            : () async {
                await context.push(
                  AppRoutes.adminMaintenanceDetail.replaceAll(
                    ':id',
                    item.id.toString(),
                  ),
                );
                if (mounted) {
                  ref
                      .read(adminMaintenanceProvider.notifier)
                      .fetchRequests(refresh: true);
                }
              },
      ),
    );
  }
}
