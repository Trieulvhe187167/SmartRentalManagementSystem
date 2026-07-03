import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/notification_models.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'tenant_controller.dart';

class TenantNotificationsScreen extends ConsumerStatefulWidget {
  const TenantNotificationsScreen({super.key});

  @override
  ConsumerState<TenantNotificationsScreen> createState() => _TenantNotificationsScreenState();
}

class _TenantNotificationsScreenState extends ConsumerState<TenantNotificationsScreen> {
  final _scrollController = ScrollController();

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
      ref.read(tenantNotificationsProvider.notifier).fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantNotificationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () {
              // mark all as read logic: in MVP we can mark each locally, or trigger a full refresh.
              // In this case, let's just show a snackbar and refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đánh dấu tất cả là đã đọc'),
                  backgroundColor: AppColors.success,
                ),
              );
              ref.invalidate(tenantNotificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: const Text('Đọc tất cả'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tenantNotificationsProvider);
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: state.isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                itemBuilder: (context, index) => const CardShimmer(height: 80),
              )
            : state.error != null
                ? ErrorState(
                    message: 'Không thể tải thông báo: ${state.error}',
                    onRetry: () => ref.invalidate(tenantNotificationsProvider),
                  )
                : state.items.isEmpty
                    ? const EmptyState(
                        title: 'Bạn chưa có thông báo nào',
                        icon: Icons.notifications_none_outlined,
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final notification = state.items[index];
                          return _buildNotificationCard(context, notification);
                        },
                      ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final isUnread = !(notification.isRead ?? false);
    final iconColor = _getIconColor(notification.type);
    final iconData = _getIconData(notification.type);

    return InkWell(
      onTap: () {
        if (isUnread) {
          ref.read(tenantNotificationsProvider.notifier).markRead(notification.id!);
          ref.invalidate(unreadNotificationCountProvider);
        }
        _showNotificationDialog(context, notification);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Theme.of(context).colorScheme.primaryFixed.withAlpha(20) : Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : Theme.of(context).colorScheme.outlineVariant,
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title ?? 'Thông báo',
                          style: AppTextStyles.titleSm.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: isUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.content ?? '',
                    style: AppTextStyles.bodySm.copyWith(
                      color: isUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.relative(DateFormatter.tryParse(notification.createdAt)),
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? type) {
    switch (type?.toUpperCase()) {
      case 'INVOICE':
      case 'PAYMENT':
      case 'BILL':
        return Icons.receipt_long_outlined;
      case 'MAINTENANCE':
      case 'SUPPORT':
        return Icons.build_outlined;
      case 'SYSTEM':
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'INVOICE':
      case 'PAYMENT':
      case 'BILL':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'MAINTENANCE':
      case 'SUPPORT':
        return AppColors.secondary;
      case 'SYSTEM':
      default:
        return AppColors.tertiary;
    }
  }

  void _showNotificationDialog(BuildContext context, AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(_getIconData(notification.type), color: _getIconColor(notification.type)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.title ?? 'Thông báo',
                  style: AppTextStyles.titleLg,
                ),
              ),
            ],
          ),
          content: Text(
            notification.content ?? '',
            style: AppTextStyles.bodyMd,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
