import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final error = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
          confirmPassword: _confirmCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // ─── Visual Accent / Illustration ───────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Bảo mật tài khoản', style: AppTextStyles.headlineSm),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới để cập nhật bảo mật cho tài khoản của bạn.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Input Form Fields ────────────────────────
              // Current Password
              _buildPasswordField(
                controller: _currentCtrl,
                label: 'Mật khẩu hiện tại',
                prefixIcon: Icons.lock_outline,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              const SizedBox(height: 20),

              // New Password
              _buildPasswordField(
                controller: _newCtrl,
                label: 'Mật khẩu mới',
                prefixIcon: Icons.vpn_key_outlined,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (v.length < 8) return 'Mật khẩu mới phải có ít nhất 8 ký tự';
                  // Simple password rule regex validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 6),
              // Password Helper info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mật khẩu phải có ít nhất 8 ký tự, bao gồm cả chữ cái và chữ số.',
                      style: AppTextStyles.labelMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confirm New Password
              _buildPasswordField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu mới',
                prefixIcon: Icons.verified_user_outlined,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v != _newCtrl.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // Action button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Cập nhật mật khẩu', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
