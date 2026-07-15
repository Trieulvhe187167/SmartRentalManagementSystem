import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          ? _formatMoneyDigits(room.monthlyRent.toStringAsFixed(0))
          : '';
      _depositCtrl.text = _formatMoneyDigits(
        room.defaultDeposit.toStringAsFixed(0),
      );
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

  String _formatMoneyDigits(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  TextInputFormatter get _moneyFormatter =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final formatted = _formatMoneyDigits(newValue.text);
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });

  Widget _buildEditScreen(
    AsyncValue<List<Building>> buildingsAsync,
    AsyncValue<List<Floor>> floorsAsync,
  ) {
    const pageBackground = Color(0xFFF6F7FC);
    const blue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 38,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, size: 19),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Chỉnh sửa Phòng ${widget.existingRoom?.roomNumber ?? ''}',
          style: AppTextStyles.titleSm.copyWith(
            color: const Color(0xFF1E293B),
            fontSize: 13,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Lưu thay đổi',
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, color: blue, size: 20),
          ),
          const SizedBox(width: 2),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE9ECF3)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _editCard(
                icon: Icons.home_outlined,
                title: 'Thông tin cơ bản',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _editLabel('Số phòng', required: true),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _roomNumberCtrl,
                      decoration: _compactDecoration(),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập số phòng'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _editLabel('Tòa nhà', required: true),
                    const SizedBox(height: 5),
                    buildingsAsync.when(
                      data: (buildings) => DropdownButtonFormField<int>(
                        initialValue:
                            buildings.any((b) => b.id == _selectedBuildingId)
                            ? _selectedBuildingId
                            : null,
                        decoration: _compactDecoration(),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        items: buildings
                            .map(
                              (building) => DropdownMenuItem<int>(
                                value: building.id,
                                child: Text(
                                  building.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBuildingId = value;
                            _selectedFloorId = null;
                          });
                          ref.invalidate(adminFloorsListProvider(value));
                        },
                        validator: (value) =>
                            value == null ? 'Vui lòng chọn tòa nhà' : null,
                      ),
                      loading: () => const CardShimmer(height: 42),
                      error: (_, _) => const Text(
                        'Không tải được danh sách tòa nhà',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _editLabel('Tầng', required: true),
                              const SizedBox(height: 5),
                              floorsAsync.when(
                                data: (floors) => DropdownButtonFormField<int>(
                                  initialValue:
                                      floors.any(
                                        (floor) => floor.id == _selectedFloorId,
                                      )
                                      ? _selectedFloorId
                                      : null,
                                  decoration: _compactDecoration(),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                  ),
                                  items: floors
                                      .map(
                                        (floor) => DropdownMenuItem<int>(
                                          value: floor.id,
                                          child: Text(
                                            floor.name?.isNotEmpty == true
                                                ? floor.name!
                                                : 'Tầng ${floor.floorNumber}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedFloorId = value),
                                  validator: (value) => value == null
                                      ? 'Vui lòng chọn tầng'
                                      : null,
                                ),
                                loading: () => const CardShimmer(height: 42),
                                error: (_, _) => const SizedBox(
                                  height: 42,
                                  child: Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _editLabel('Diện tích (m²)'),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _areaCtrl,
                                decoration: _compactDecoration(suffix: 'm²'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validateArea,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _editLabel('Số người tối đa'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _maxOccupantsCtrl,
                      decoration: _compactDecoration(
                        prefix: const Icon(Icons.person_outline, size: 17),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateMaxOccupants,
                    ),
                  ],
                ),
              ),
              _editCard(
                icon: Icons.attach_money_rounded,
                title: 'Giá thuê',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _editLabel('Giá thuê hàng tháng (đ)', required: true),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _rentCtrl,
                      decoration: _compactDecoration(suffix: 'đ'),
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      inputFormatters: [_moneyFormatter],
                      keyboardType: TextInputType.number,
                      validator: _validateRent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nhập số tiền bằng đồng Việt Nam',
                      style: AppTextStyles.labelSm.copyWith(
                        color: const Color(0xFF64748B),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              _editCard(
                icon: Icons.description_outlined,
                title: 'Mô tả (tùy chọn)',
                child: TextFormField(
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: _compactDecoration(
                    hint: 'Nhập mô tả về phòng',
                    verticalPadding: 12,
                  ),
                ),
              ),
              _editCard(
                icon: Icons.toggle_on_outlined,
                title: 'Trạng thái phòng',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _editStatusOption(
                      value: 'AVAILABLE',
                      label: 'Trống',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF0F8A6A),
                      lightColor: const Color(0xFFEAF8F4),
                    ),
                    _editStatusOption(
                      value: 'OCCUPIED',
                      label: 'Đã thuê',
                      icon: Icons.check,
                      color: blue,
                      lightColor: const Color(0xFFEDF3FF),
                    ),
                    _editStatusOption(
                      value: 'MAINTENANCE',
                      label: 'Bảo trì',
                      icon: Icons.build_outlined,
                      color: const Color(0xFF9A6517),
                      lightColor: const Color(0xFFFFF7E8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8EBF2))),
          ),
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF93B4F8),
                elevation: 3,
                shadowColor: blue.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 17),
              label: const Text('Lưu thay đổi'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF075EEB)),
              const SizedBox(width: 5),
              Text(
                title,
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _editLabel(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ]
            : null,
      ),
      style: AppTextStyles.labelSm.copyWith(
        color: const Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }

  InputDecoration _compactDecoration({
    String? hint,
    String? suffix,
    Widget? prefix,
    double verticalPadding = 10,
  }) {
    const borderColor = Color(0xFFCBD3E1);
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      prefixIcon: prefix,
      prefixIconConstraints: prefix == null
          ? null
          : const BoxConstraints(minWidth: 34, minHeight: 38),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 11,
        vertical: verticalPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  String? _validateArea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập diện tích';
    }
    final area = double.tryParse(value.trim().replaceAll(',', '.'));
    return area == null || area <= 0 ? 'Diện tích không hợp lệ' : null;
  }

  String? _validateMaxOccupants(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số người';
    }
    final occupants = int.tryParse(value.trim());
    return occupants == null || occupants < 1 ? 'Số người không hợp lệ' : null;
  }

  String? _validateRent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập giá thuê';
    }
    final rent = double.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
    return rent == null || rent <= 0 ? 'Giá thuê không hợp lệ' : null;
  }

  Widget _editStatusOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color lightColor,
  }) {
    final selected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : lightColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : color.withAlpha(45)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withAlpha(50),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(adminBuildingsListProvider);
    final floorsAsync = ref.watch(adminFloorsListProvider(_selectedBuildingId));

    if (_isEdit) {
      return _buildEditScreen(buildingsAsync, floorsAsync);
    }

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
