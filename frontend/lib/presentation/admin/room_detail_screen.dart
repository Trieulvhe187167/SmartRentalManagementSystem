import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/room_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

final adminRoomDetailProvider = FutureProvider.family<Room, int>((
  ref,
  roomId,
) async {
  return AdminRepository.instance.room(roomId);
});

class AdminRoomDetailScreen extends ConsumerStatefulWidget {
  final int roomId;

  const AdminRoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<AdminRoomDetailScreen> createState() =>
      _AdminRoomDetailScreenState();
}

class _AdminRoomDetailScreenState extends ConsumerState<AdminRoomDetailScreen> {
  bool _submitting = false;

  Future<void> _openEditRoom(Room room) async {
    final updated = await context.push<bool>(
      AppRoutes.adminRoomForm,
      extra: <String, dynamic>{'roomId': room.id, 'room': room},
    );

    if (updated == true) {
      ref.invalidate(adminRoomDetailProvider(widget.roomId));
      ref.invalidate(adminRoomsProvider);
    }
  }

  Future<void> _toggleRoomStatus(Room room) async {
    setState(() => _submitting = true);
    try {
      final isActive = room.status.toUpperCase() != 'INACTIVE';
      if (isActive) {
        await AdminRepository.instance.deactivateRoom(widget.roomId);
      } else {
        await AdminRepository.instance.activateRoom(widget.roomId);
      }
      ref.invalidate(adminRoomDetailProvider(widget.roomId));
      ref.invalidate(adminRoomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Đã tạm ngưng hoạt động phòng'
                  : 'Đã kích hoạt hoạt động phòng',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomDetailAsync = ref.watch(adminRoomDetailProvider(widget.roomId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết phòng'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        actions: [
          roomDetailAsync.maybeWhen(
            data: (room) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa phòng',
              onPressed: _submitting ? null : () => _openEditRoom(room),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          roomDetailAsync.maybeWhen(
            data: (room) => IconButton(
              icon: Icon(
                room.status.toUpperCase() == 'INACTIVE'
                    ? Icons.play_circle_outline
                    : Icons.pause_circle_outline,
                color: room.status.toUpperCase() == 'INACTIVE'
                    ? AppColors.success
                    : AppColors.danger,
              ),
              onPressed: _submitting ? null : () => _toggleRoomStatus(room),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: roomDetailAsync.when(
        data: (room) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Phòng ${room.roomNumber}',
                          style: AppTextStyles.headlineSm,
                        ),
                        StatusChip(status: room.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toà nhà: ${room.building ?? '—'} · Tầng ${room.floor ?? '—'}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),
                    _buildInfoRow('Diện tích', '${room.area ?? 0} m²'),
                    _buildInfoRow(
                      'Giá thuê',
                      '${CurrencyFormatter.format(room.monthlyRent)}/tháng',
                      valueColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    _buildInfoRow(
                      'Số người ở tối đa',
                      '${room.maxOccupants ?? 4} người',
                    ),
                    if (room.description != null &&
                        room.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 14),
                      Text('Mô tả', style: AppTextStyles.titleSm),
                      const SizedBox(height: 8),
                      Text(
                        room.description!,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        loading: () => const PageLoading(message: 'Đang tải chi tiết phòng...'),
        error: (err, stack) => ErrorState(
          message: 'Không thể tải chi tiết phòng',
          onRetry: () => ref.invalidate(adminRoomDetailProvider(widget.roomId)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
