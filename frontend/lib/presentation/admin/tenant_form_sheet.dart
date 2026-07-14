import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/tenant_models.dart';

class TenantEditFormSheet extends StatefulWidget {
  final TenantProfile tenant;
  final Future<String?> Function(TenantRequest req) onSubmit;

  const TenantEditFormSheet({
    super.key,
    required this.tenant,
    required this.onSubmit,
  });

  @override
  State<TenantEditFormSheet> createState() => _TenantEditFormSheetState();
}

class _TenantEditFormSheetState extends State<TenantEditFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _idNoCtrl = TextEditingController();
  final _issuedDateCtrl = TextEditingController();
  final _issuedPlaceCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  String _idType = 'CCCD';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final tenant = widget.tenant;
    _nameCtrl.text = tenant.fullName ?? '';
    _phoneCtrl.text = tenant.phone ?? '';
    _emailCtrl.text = tenant.email ?? '';
    _dobCtrl.text = tenant.dateOfBirth ?? '1990-01-01';
    _idNoCtrl.text = tenant.idNumber ?? '';
    _idType = tenant.idType ?? 'CCCD';
    _issuedDateCtrl.text = tenant.identityIssuedDate ?? '';
    _issuedPlaceCtrl.text = tenant.identityIssuedPlace ?? '';
    _addrCtrl.text = tenant.address ?? '';
    _emergencyNameCtrl.text = tenant.emergencyContactName ?? '';
    _emergencyPhoneCtrl.text = tenant.emergencyContactPhone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _idNoCtrl.dispose();
    _issuedDateCtrl.dispose();
    _issuedPlaceCtrl.dispose();
    _addrCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _optionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Email không hợp lệ';
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(controller.text);
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null) return;
    controller.text =
        '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.tenant.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khách thuê chưa có tài khoản liên kết'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await widget.onSubmit(
      TenantRequest(
        userId: widget.tenant.userId,
        fullName: _nameCtrl.text.trim(),
        phone: _trimOrNull(_phoneCtrl.text),
        email: _trimOrNull(_emailCtrl.text),
        dateOfBirth: _dobCtrl.text.trim(),
        idType: _idType,
        idNumber: _idNoCtrl.text.trim(),
        identityIssuedDate: _trimOrNull(_issuedDateCtrl.text),
        identityIssuedPlace: _trimOrNull(_issuedPlaceCtrl.text),
        address: _addrCtrl.text.trim(),
        emergencyContactName: _trimOrNull(_emergencyNameCtrl.text),
        emergencyContactPhone: _trimOrNull(_emergencyPhoneCtrl.text),
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Chỉnh sửa thông tin khách thuê',
                style: AppTextStyles.headlineSm,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: _decoration('Họ và tên *', icon: Icons.person),
                textInputAction: TextInputAction.next,
                validator: (v) => _required(v, 'Vui lòng nhập họ tên'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                decoration: _decoration(
                  'Ngày sinh *',
                  icon: Icons.calendar_today,
                ),
                onTap: () => _pickDate(_dobCtrl),
                validator: (v) => _required(v, 'Vui lòng chọn ngày sinh'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: _decoration(
                        'Số điện thoại',
                        icon: Icons.phone,
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: _decoration('Email', icon: Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _optionalEmail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idNoCtrl,
                      decoration: _decoration(
                        'Số CMND/CCCD *',
                        icon: Icons.badge,
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          _required(v, 'Vui lòng nhập số giấy tờ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _idType,
                      decoration: _decoration('Loại giấy tờ *'),
                      items: const [
                        DropdownMenuItem(value: 'CCCD', child: Text('CCCD')),
                        DropdownMenuItem(value: 'CMND', child: Text('CMND')),
                        DropdownMenuItem(
                          value: 'PASSPORT',
                          child: Text('Hộ chiếu'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _idType = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _issuedDateCtrl,
                      readOnly: true,
                      decoration: _decoration(
                        'Ngày cấp',
                        icon: Icons.event_note,
                      ),
                      onTap: () => _pickDate(_issuedDateCtrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _issuedPlaceCtrl,
                      decoration: _decoration(
                        'Nơi cấp',
                        icon: Icons.location_city,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addrCtrl,
                decoration: _decoration(
                  'Địa chỉ thường trú *',
                  icon: Icons.home,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: (v) => _required(v, 'Vui lòng nhập địa chỉ'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emergencyNameCtrl,
                      decoration: _decoration(
                        'Người liên hệ khẩn cấp',
                        icon: Icons.contact_phone,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emergencyPhoneCtrl,
                      decoration: _decoration(
                        'Số điện thoại khẩn cấp',
                        icon: Icons.phone_in_talk,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
