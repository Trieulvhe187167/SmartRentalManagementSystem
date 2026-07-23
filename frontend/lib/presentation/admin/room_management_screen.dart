import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/room_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

final adminBuildingsListProvider = FutureProvider<List<Building>>((ref) async {
  final res = await AdminRepository.instance.buildings(size: 100);
  return res.content.where((b) => b.status != 'INACTIVE').toList();
});

final adminFloorsListProvider = FutureProvider.family<List<Floor>, int?>((
  ref,
  buildingId,
) async {
  final res = await AdminRepository.instance.floors(
    buildingId: buildingId,
    size: 100,
  );
  return res.content.where((f) => f.status != 'INACTIVE').toList();
});

class AdminRoomManagementScreen extends ConsumerStatefulWidget {
  const AdminRoomManagementScreen({super.key});

  @override
  ConsumerState<AdminRoomManagementScreen> createState() =>
      _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState
    extends ConsumerState<AdminRoomManagementScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminRoomsProvider.notifier).fetchRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRoomsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            onPressed: () => context.push(AppRoutes.adminRoomForm),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(adminRoomsProvider.notifier).fetchRooms(refresh: true);
        },
        child: Column(
          children: [
            // ─── Search & Stats Bar ──────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phòng theo số phòng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(adminRoomsProvider.notifier)
                                    .updateSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      ref
                          .read(adminRoomsProvider.notifier)
                          .updateSearch(v.trim());
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filter bar
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('ALL', 'Tất cả'),
                        const SizedBox(width: 8),
                        _buildFilterChip('AVAILABLE', 'Trống'),
                        const SizedBox(width: 8),
                        _buildFilterChip('OCCUPIED', 'Đang thuê'),
                        const SizedBox(width: 8),
                        _buildFilterChip('MAINTENANCE', 'Bảo trì'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Room List ───────────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          const CardShimmer(height: 110),
                    )
                  : state.error != null
                  ? ErrorState(
                      message: 'Lỗi tải phòng: ${state.error}',
                      onRetry: () => ref
                          .read(adminRoomsProvider.notifier)
                          .fetchRooms(refresh: true),
                    )
                  : state.items.isEmpty
                  ? const EmptyState(
                      title: 'Không tìm thấy phòng nào',
                      subtitle: 'Gõ tìm kiếm khác hoặc thêm phòng mới',
                      icon: Icons.meeting_room_outlined,
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount:
                          state.items.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final room = state.items[index];
                        return _buildRoomCard(context, room);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () => context.push(AppRoutes.adminRoomForm),
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
          ref.read(adminRoomsProvider.notifier).updateStatus(value);
        }
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, Room room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Phòng ${room.roomNumber}',
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            StatusChip(status: room.status ?? 'AVAILABLE'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: AppColors.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tầng ${room.floor ?? '—'} · ${room.building ?? '—'}',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.aspect_ratio,
                  size: 16,
                  color: AppColors.outline,
                ),
                const SizedBox(width: 4),
                Text('${room.area ?? 0} m²', style: AppTextStyles.bodySm),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Giá thuê: ${CurrencyFormatter.format(room.monthlyRent)}/tháng',
              style: AppTextStyles.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => context.push(AppRoutes.roomDetail(room.id!)),
      ),
    );
  }

  void _showCreateRoomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CreateRoomForm(
          onSubmit: (req) async {
            final error = await ref
                .read(adminRoomsProvider.notifier)
                .createRoom(req);
            if (context.mounted) {
              Navigator.pop(context);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thêm phòng mới thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _CreateRoomForm extends ConsumerStatefulWidget {
  final Function(RoomRequest req) onSubmit;

  const _CreateRoomForm({required this.onSubmit});

  @override
  ConsumerState<_CreateRoomForm> createState() => _CreateRoomFormState();
}

class _CreateRoomFormState extends ConsumerState<_CreateRoomForm> {
  final _formKey = GlobalKey<FormState>();
  final _roomNoCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _buildingId;
  int? _floorId;

  @override
  void dispose() {
    _roomNoCtrl.dispose();
    _areaCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _maxCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(adminBuildingsListProvider);
    final floorsAsync = ref.watch(adminFloorsListProvider(_buildingId));

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Text('Thêm phòng mới', style: AppTextStyles.headlineSm),
              const SizedBox(height: 20),

              // Room number
              TextFormField(
                controller: _roomNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số phòng',
                  hintText: 'Ví dụ: 101, 202',
                ),
                keyboardType: TextInputType.text,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập số phòng'
                    : null,
              ),
              const SizedBox(height: 16),

              // Floor Selection
              DropdownButtonFormField<int>(
                value: _floorId,
                decoration: const InputDecoration(labelText: 'Tầng'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Tầng 1')),
                  DropdownMenuItem(value: 2, child: Text('Tầng 2')),
                  DropdownMenuItem(value: 3, child: Text('Tầng 3')),
                  DropdownMenuItem(value: 4, child: Text('Tầng 4')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _floorId = v);
                },
              ),
              const SizedBox(height: 16),

              // Area & Max occupants row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Diện tích (m²)',
                        hintText: 'Ví dụ: 25',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập diện tích'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số người tối đa',
                        hintText: 'Ví dụ: 3',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập số người'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rent price
              TextFormField(
                controller: _rentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Giá thuê hàng tháng (VND)',
                  hintText: 'Ví dụ: 3500000',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập giá thuê'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả thêm',
                  hintText: 'Mô tả trang bị phòng (điều hoà, giường...)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit(
                        RoomRequest(
                          roomNumber: _roomNoCtrl.text.trim(),
                          floor: _floorId,
                          building: 'Lumina Building',
                          area: double.tryParse(_areaCtrl.text.trim()) ?? 0.0,
                          monthlyRent:
                              double.tryParse(_rentCtrl.text.trim()) ?? 0.0,
                          maxOccupants: int.tryParse(_maxCtrl.text.trim()) ?? 4,
                          status: 'AVAILABLE',
                          description: _descCtrl.text.trim(),
                        ),
                      );
                    }
                  },
                  child: const Text('Thêm phòng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
