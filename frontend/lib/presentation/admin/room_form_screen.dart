import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/room_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/app_card.dart';
import 'room_management_screen.dart';

class AdminRoomFormScreen extends ConsumerStatefulWidget {
  final int? roomId;
  final Room? existingRoom;

  const AdminRoomFormScreen({super.key, this.roomId, this.existingRoom});

  @override
  ConsumerState<AdminRoomFormScreen> createState() =>
      _AdminRoomFormScreenState();
}

class _AdminRoomFormScreenState extends ConsumerState<AdminRoomFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _roomNumberCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _maxOccupantsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // State
  int? _selectedBuildingId;
  int? _selectedFloorId;
  String _selectedStatus = 'AVAILABLE';
  bool _isSubmitting = false;

  bool get _isEdit => widget.roomId != null;

  @override
  void initState() {
    super.initState();
    final room = widget.existingRoom;
    if (room != null) {
      _roomNumberCtrl.text = room.roomNumber;
      _areaCtrl.text = room.area != null ? room.area!.toStringAsFixed(0) : '';
      _rentCtrl.text = room.monthlyRent > 0
          ? room.monthlyRent.toStringAsFixed(0)
          : '';
      _depositCtrl.text = room.defaultDeposit.toStringAsFixed(0);
      _maxOccupantsCtrl.text = room.maxOccupants != null
          ? room.maxOccupants.toString()
          : '';
      _descCtrl.text = room.description ?? '';
      _selectedBuildingId = room.buildingId;
      _selectedFloorId = room.floorId;
      _selectedStatus = room.status;
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _areaCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _maxOccupantsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label, {
    String? suffix,
    String? helper,
  }) => InputDecoration(
    labelText: label,
    suffixText: suffix,
    helperText: helper,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _sectionHeader(BuildContext context, IconData icon, String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.titleMd),
          ],
        ),
      );

  Widget _buildCard({required Widget child, EdgeInsets? margin}) => Padding(
    padding: margin ?? EdgeInsets.zero,
    child: AppCard(padding: const EdgeInsets.all(20), child: child),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFloorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tầng cho phòng'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final req = RoomRequest(
        roomNumber: _roomNumberCtrl.text.trim(),
        buildingId: _selectedBuildingId!,
        floorId: _selectedFloorId!,
        areaM2: double.parse(_areaCtrl.text.trim().replaceAll(',', '.')),
        defaultRent: _parseMoney(_rentCtrl.text),
        defaultDeposit: _parseMoney(_depositCtrl.text),
        maxOccupants: int.parse(_maxOccupantsCtrl.text.trim()),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );

      if (_isEdit) {
        await AdminRepository.instance.updateRoom(widget.roomId!, req);
        if (_selectedStatus != widget.existingRoom?.status) {
          await AdminRepository.instance.updateRoomStatus(
            widget.roomId!,
            _selectedStatus,
          );
        }
      } else {
        await AdminRepository.instance.createRoom(req);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Cập nhật phòng thành công' : 'Thêm phòng thành công',
            ),
            backgroundColor: AppColors.success,
          ),
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

  double _parseMoney(String value) =>
      double.parse(value.trim().replaceAll('.', '').replaceAll(',', ''));

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(adminBuildingsListProvider);
    final floorsAsync = ref.watch(adminFloorsListProvider(_selectedBuildingId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Chỉnh sửa Phòng ${widget.existingRoom?.roomNumber ?? ""}'
              : 'Thêm Phòng Mới',
          style: AppTextStyles.titleLg,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            tooltip: 'Lưu phòng',
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Section 1: Thông tin cơ bản ────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      context,
                      Icons.home_outlined,
                      'Thông tin cơ bản',
                    ),
                    const Divider(height: 0),
                    const SizedBox(height: 20),

                    // Số phòng
                    TextFormField(
                      controller: _roomNumberCtrl,
                      decoration: _inputDecoration('Số phòng *'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập số phòng'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Tòa nhà
                    buildingsAsync.when(
                      data: (buildings) => DropdownButtonFormField<int>(
                        value:
                            _selectedBuildingId != null &&
                                buildings.any(
                                  (b) => b.id == _selectedBuildingId,
                                )
                            ? _selectedBuildingId
                            : null,
                        decoration: _inputDecoration('Tòa nhà *'),
                        isExpanded: true,
                        items: buildings
                            .map(
                              (b) => DropdownMenuItem<int>(
                                value: b.id,
                                child: Text(
                                  b.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBuildingId = val;
                            _selectedFloorId = null;
                          });
                          ref.invalidate(adminFloorsListProvider(val));
                        },
                        validator: (v) =>
                            v == null ? 'Vui lòng chọn tòa nhà' : null,
                      ),
                      loading: () => const CardShimmer(height: 56),
                      error: (e, _) => DropdownButtonFormField<int>(
                        value: null,
                        decoration: _inputDecoration('Tòa nhà *'),
                        items: const [],
                        onChanged: null,
                        hint: Text(
                          'Không tải được danh sách tòa',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Tầng
                    floorsAsync.when(
                      data: (floors) => DropdownButtonFormField<int>(
                        value:
                            _selectedFloorId != null &&
                                floors.any((f) => f.id == _selectedFloorId)
                            ? _selectedFloorId
                            : null,
                        decoration: _inputDecoration('Tầng *').copyWith(
                          enabled: _selectedBuildingId != null,
                          hintText: _selectedBuildingId == null
                              ? 'Chọn tòa nhà trước'
                              : null,
                        ),
                        isExpanded: true,
                        disabledHint: Text(
                          'Chọn tòa nhà trước',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        items: _selectedBuildingId == null
                            ? []
                            : floors
                                  .map(
                                    (f) => DropdownMenuItem<int>(
                                      value: f.id,
                                      child: Text(
                                        f.name != null && f.name!.isNotEmpty
                                            ? f.name!
                                            : 'Tầng ${f.floorNumber}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        onChanged: _selectedBuildingId == null
                            ? null
                            : (val) {
                                setState(() => _selectedFloorId = val);
                              },
                        validator: (v) =>
                            v == null ? 'Vui lòng chọn tầng' : null,
                      ),
                      loading: () => const CardShimmer(height: 56),
                      error: (e, _) => DropdownButtonFormField<int>(
                        value: null,
                        decoration: _inputDecoration('Tầng *'),
                        items: const [],
                        onChanged: null,
                        hint: Text(
                          'Không tải được danh sách tầng',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Diện tích
                    TextFormField(
                      controller: _areaCtrl,
                      decoration: _inputDecoration(
                        'Diện tích (m²) *',
                        suffix: 'm²',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập diện tích';
                        }
                        final parsed = double.tryParse(
                          v.trim().replaceAll(',', '.'),
                        );
                        if (parsed == null || parsed <= 0) {
                          return 'Diện tích phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Số người tối đa
                    TextFormField(
                      controller: _maxOccupantsCtrl,
                      decoration: _inputDecoration('Số người tối đa *'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập số người tối đa';
                        }
                        final parsed = int.tryParse(v.trim());
                        if (parsed == null || parsed < 1) {
                          return 'Số người phải từ 1 trở lên';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // ─── Section 2: Giá thuê ────────────────────────────────────
              _buildCard(
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      context,
                      Icons.attach_money_rounded,
                      'Giá thuê',
                    ),
                    const Divider(height: 0),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _rentCtrl,
                      decoration: _inputDecoration(
                        'Giá thuê hàng tháng (₫) *',
                        helper: 'Nhập số tiền bằng đồng Việt Nam',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập giá thuê';
                        }
                        final cleaned = v
                            .trim()
                            .replaceAll('.', '')
                            .replaceAll(',', '');
                        final parsed = double.tryParse(cleaned);
                        if (parsed == null || parsed <= 0) {
                          return 'Giá thuê không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _depositCtrl,
                      decoration: _inputDecoration(
                        'Tiền đặt cọc (₫) *',
                        helper: 'Nhập 0 nếu phòng không yêu cầu đặt cọc',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập tiền đặt cọc';
                        }
                        final value = double.tryParse(
                          v.trim().replaceAll('.', '').replaceAll(',', ''),
                        );
                        if (value == null || value < 0) {
                          return 'Tiền đặt cọc không được âm';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // ─── Section 3: Mô tả ───────────────────────────────────────
              _buildCard(
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      context,
                      Icons.description_outlined,
                      'Mô tả',
                    ),
                    const Divider(height: 0),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDecoration('Mô tả phòng'),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              ),

              // ─── Section 4: Trạng thái (Edit only) ─────────────────────
              if (_isEdit)
                _buildCard(
                  margin: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        context,
                        Icons.toggle_on_outlined,
                        'Trạng thái',
                      ),
                      const Divider(height: 0),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildStatusChip(
                            value: 'AVAILABLE',
                            label: 'Trống',
                            selectedColor: AppColors.success,
                            selectedBgColor: AppColors.successLight,
                          ),
                          _buildStatusChip(
                            value: 'OCCUPIED',
                            label: 'Đã thuê',
                            selectedColor: AppColors.primaryContainer,
                            selectedBgColor: AppColors.primaryFixed,
                          ),
                          _buildStatusChip(
                            value: 'MAINTENANCE',
                            label: 'Bảo trì',
                            selectedColor: AppColors.warning,
                            selectedBgColor: AppColors.warningLight,
                          ),
                          _buildStatusChip(
                            value: 'INACTIVE',
                            label: 'Ngừng hoạt động',
                            selectedColor: AppColors.neutral,
                            selectedBgColor: AppColors.neutralLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ─── Submit Button ───────────────────────────────────────────
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(120),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Lưu thay đổi' : 'Lưu phòng',
                          style: AppTextStyles.titleSm.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String value,
    required String label,
    required Color selectedColor,
    required Color selectedBgColor,
  }) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: isSelected ? selectedColor : AppColors.outline,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedColor: selectedBgColor,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      side: BorderSide(
        color: isSelected ? selectedColor : AppColors.outlineVariant,
        width: isSelected ? 1.5 : 1,
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatus = value);
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}
