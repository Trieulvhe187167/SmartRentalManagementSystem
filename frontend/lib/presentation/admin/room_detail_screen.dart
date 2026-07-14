import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/room_models.dart';
import '../../data/models/contract_models.dart';
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

final adminRoomActiveContractProvider =
    FutureProvider.family<RentalContract?, int>((ref, roomId) async {
      return AdminRepository.instance.currentRoomContract(roomId);
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
        data: (room) {
          final isOccupied = room.status.toUpperCase() == 'OCCUPIED';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Room Basic Header ────────────────────
                AppCard(
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
                      const SizedBox(height: 6),
                      Text(
                        'Toà nhà: ${room.building ?? '—'} · Tầng ${room.floor ?? '—'}',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
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
                        const SizedBox(height: 8),
                        Text(
                          'Mô tả thêm:',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(room.description!, style: AppTextStyles.bodySm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Occupancy info ────────────────────────
                if (isOccupied) ...[
                  Text(
                    'Thông tin khách thuê hiện tại',
                    style: AppTextStyles.titleMd,
                  ),
                  const SizedBox(height: 12),
                  _buildActiveContractCard(),
                  const SizedBox(height: 20),
                ],

                // ─── Operations Actions ───────────────────
                Text('Hành động quản lý', style: AppTextStyles.titleMd),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.bolt,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Ghi chỉ số điện nước'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => context.go(AppRoutes.adminMeterReadings),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.add_card_outlined,
                          color: AppColors.success,
                        ),
                        title: const Text('Tạo hợp đồng mới'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        enabled: room.status.toUpperCase() == 'AVAILABLE',
                        onTap: () =>
                            context.push(AppRoutes.adminCreateContract),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const PageLoading(message: 'Đang tải chi tiết phòng...'),
        error: (err, stack) => ErrorState(
          message: 'Không thể tải chi tiết phòng',
          onRetry: () => ref.invalidate(adminRoomDetailProvider(widget.roomId)),
        ),
      ),
    );
  }

  Widget _buildActiveContractCard() {
    final contractAsync = ref.watch(
      adminRoomActiveContractProvider(widget.roomId),
    );
    return AppCard(
      child: contractAsync.when(
        loading: () => const CardShimmer(height: 130),
        error: (error, _) => ErrorState(
          message: 'Không thể tải hợp đồng đang hoạt động',
          onRetry: () =>
              ref.invalidate(adminRoomActiveContractProvider(widget.roomId)),
        ),
        data: (contract) {
          if (contract == null) {
            return const EmptyState(
              title: 'Không tìm thấy hợp đồng active',
              subtitle: 'Trạng thái phòng và hợp đồng đang không đồng bộ.',
              icon: Icons.assignment_late_outlined,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contract.tenantName ?? 'Khách thuê chưa có tên',
                      style: AppTextStyles.titleMd,
                    ),
                  ),
                  StatusChip(status: contract.status ?? 'ACTIVE'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Mã hợp đồng',
                contract.contractNumber ?? 'HD-${contract.id}',
              ),
              _buildInfoRow('Ngày bắt đầu', contract.startDate ?? '—'),
              _buildInfoRow('Ngày kết thúc', contract.endDate ?? '—'),
              _buildInfoRow(
                'Giá thuê',
                contract.monthlyRent == null
                    ? '—'
                    : '${CurrencyFormatter.format(contract.monthlyRent!)}/tháng',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.adminContracts),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Xem danh sách hợp đồng'),
              ),
            ],
          );
        },
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
