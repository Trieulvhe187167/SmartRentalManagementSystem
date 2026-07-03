import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_identifierCtrl.text.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Không thể gửi yêu cầu khôi phục'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final token = result.resetToken?.trim();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy tài khoản đang hoạt động với thông tin này.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yêu cầu khôi phục mật khẩu thành công!'),
        backgroundColor: AppColors.success,
      ),
    );

    context.push(
      '/reset-password?username=${Uri.encodeComponent(_identifierCtrl.text.trim())}',
      extra: token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
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
                        Icons.person_search_outlined,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Tìm tài khoản của bạn', style: AppTextStyles.headlineSm),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng nhập tên đăng nhập hoặc địa chỉ email đã đăng ký để bắt đầu khôi phục mật khẩu.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Input Form Fields ────────────────────────
              TextFormField(
                controller: _identifierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập hoặc Email',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập hoặc email';
                  }
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
                      : const Text('Tiếp tục', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
