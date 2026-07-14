import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/password_validator.dart';
import 'auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;
  final String? username;

  const ResetPasswordScreen({super.key, this.initialToken, this.username});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasToken => widget.initialToken?.trim().isNotEmpty ?? false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authControllerProvider.notifier)
        .resetForgottenPassword(
          token: widget.initialToken!.trim(),
          newPassword: _newPasswordCtrl.text,
          confirmPassword: _confirmPasswordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đặt lại mật khẩu thành công! Hãy đăng nhập lại.'),
        backgroundColor: AppColors.success,
      ),
    );

    // Redirect to login screen
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasToken) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_off_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Liên kết đặt lại mật khẩu không hợp lệ',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLg,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy yêu cầu một liên kết mới từ màn hình đăng nhập.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text('Yêu cầu liên kết mới'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.lock_open,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Tạo mật khẩu mới', style: AppTextStyles.headlineSm),
                    const SizedBox(height: 8),
                    Text(
                      widget.username != null && widget.username!.isNotEmpty
                          ? 'Thiết lập mật khẩu mới cho tài khoản "${widget.username}".'
                          : 'Thiết lập mật khẩu truy cập mới.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Input Form Fields ────────────────────────
              // New Password
              _buildPasswordField(
                controller: _newPasswordCtrl,
                label: 'Mật khẩu mới',
                prefixIcon: Icons.lock_outline,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  return PasswordValidator.validateNewPassword(v);
                },
              ),
              const SizedBox(height: 6),
              // Password Helper info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.outline,
                  ),
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

              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordCtrl,
                label: 'Xác nhận mật khẩu mới',
                prefixIcon: Icons.verified_user_outlined,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  return PasswordValidator.validateConfirmation(
                    v,
                    _newPasswordCtrl.text,
                  );
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
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Đặt lại mật khẩu',
                          style: TextStyle(fontSize: 16),
                        ),
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
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
