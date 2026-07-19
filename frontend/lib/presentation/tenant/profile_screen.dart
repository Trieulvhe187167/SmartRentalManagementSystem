import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/api/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/tenant_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/avatar_picker.dart';
import '../auth/auth_controller.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'tenant_controller.dart';

final tenantProfileUserProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(authRepositoryProvider).me();
});

class TenantProfileScreen extends ConsumerWidget {
  const TenantProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authControllerProvider);
    final userAsync = ref.watch(tenantProfileUserProvider);
    final user = userAsync.asData?.value ?? userState.user;
    final dashboardAsync = ref.watch(tenantDashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── Sliver App Bar Header ────────────────
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              user?.displayName ?? 'Khách thuê',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: user == null
                          ? null
                          : () => _showEditProfileSheet(context, ref, user),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildAvatar(user, 96),
                          if (user != null)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),

          // ─── Scrollable Profile Body ──────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Contact Info Card ───────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Thông tin cá nhân',
                          style: AppTextStyles.titleLg,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: user == null
                            ? null
                            : () => _showEditProfileSheet(context, ref, user),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.person_outline,
                          'Tên đăng nhập',
                          user?.username ?? '—',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          Icons.email_outlined,
                          'Email',
                          user?.email ?? '—',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          Icons.phone_outlined,
                          'Số điện thoại',
                          user?.phone ?? '—',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          Icons.badge_outlined,
                          'CMND/CCCD',
                          user?.idNumber ?? '—',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          Icons.location_on_outlined,
                          'Địa chỉ thường trú',
                          user?.address ?? '—',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Current Room details card ───────────
                  Text('Thông tin thuê phòng', style: AppTextStyles.titleLg),
                  const SizedBox(height: 12),
                  dashboardAsync.when(
                    data: (data) {
                      final room = data.currentRoom;
                      if (room == null) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Không có thông tin phòng đang thuê hiện tại.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              Icons.meeting_room_outlined,
                              'Số phòng',
                              'Phòng ${room.roomNumber}',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              context,
                              Icons.layers_outlined,
                              'Tầng',
                              room.floor != null ? 'Tầng ${room.floor}' : '—',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              context,
                              Icons.apartment_outlined,
                              'Toà nhà',
                              room.buildingName ?? '—',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              context,
                              Icons.payments_outlined,
                              'Giá thuê hàng tháng',
                              CurrencyFormatter.format(room.monthlyRent),
                              valueColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const CardShimmer(height: 160),
                    error: (_, _) => AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Không thể tải thông tin phòng',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Actions Card ────────────────────────
                  Text('Tùy chọn', style: AppTextStyles.titleLg),
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
                            Theme.of(context).brightness == Brightness.dark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: AppColors.secondary,
                          ),
                          title: const Text('Giao diện tối (Dark Mode)'),
                          trailing: Switch(
                            value:
                                Theme.of(context).brightness == Brightness.dark,
                            onChanged: (v) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.lock_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                          title: const Text('Đổi mật khẩu tài khoản'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                          ),
                          onTap: () => context.push(AppRoutes.changePassword),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.danger,
                          ),
                          title: const Text(
                            'Đăng xuất khỏi tài khoản',
                            style: TextStyle(color: AppColors.danger),
                          ),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  title: const Text('Đăng xuất'),
                                  content: const Text(
                                    'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Đăng xuất',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirm == true && context.mounted) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go(AppRoutes.login);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    UserResponse? user,
    double size, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    final avatarData = user?.avatarData;
    if (avatarData != null && avatarData.contains(',')) {
      try {
        final bytes = base64Decode(
          avatarData.substring(avatarData.indexOf(',') + 1),
        );
        return SizedBox(
          width: size,
          height: size,
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.white.withValues(alpha: 0.18),
      child: Text(
        user?.initials ?? 'U',
        style: TextStyle(
          fontSize: size * 0.38,
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserResponse user,
  ) async {
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final addressCtrl = TextEditingController(text: user.address ?? '');
    final originalEmail = (user.email ?? '').trim().toLowerCase();
    String? avatarData = user.avatarData;
    bool avatarChanged = false;
    bool saving = false;
    EmailChangeStartResponse? emailStart;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> chooseAvatar() async {
            try {
              final picked = await pickAvatarData();
              if (picked != null && sheetContext.mounted) {
                setSheetState(() {
                  avatarData = picked;
                  avatarChanged = true;
                });
              }
            } on AvatarPickerException catch (error) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(error.message),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            }
          }

          Future<void> save() async {
            final phone = phoneCtrl.text.trim();
            final email = emailCtrl.text.trim().toLowerCase();
            final address = addressCtrl.text.trim();
            if (address.isEmpty) {
              _showSheetError(
                sheetContext,
                'Vui lòng nhập địa chỉ thường trú.',
              );
              return;
            }
            if (phone.isNotEmpty &&
                !RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
              _showSheetError(
                sheetContext,
                'Số điện thoại phải gồm 9 đến 15 chữ số.',
              );
              return;
            }
            if (originalEmail.isNotEmpty && email.isEmpty) {
              _showSheetError(sheetContext, 'Không thể xoá email đã xác minh.');
              return;
            }
            if (email.isNotEmpty &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              _showSheetError(sheetContext, 'Địa chỉ email không hợp lệ.');
              return;
            }

            setSheetState(() => saving = true);
            try {
              await TenantRepository.instance.updateProfile(
                TenantProfileUpdateRequest(
                  phone: phone.isEmpty ? null : phone,
                  permanentAddress: address,
                  avatarData: avatarChanged ? (avatarData ?? '') : null,
                ),
              );
              if (email.isNotEmpty && email != originalEmail) {
                emailStart = await TenantRepository.instance.requestEmailChange(
                  email,
                );
              }
              await ref.read(authControllerProvider.notifier).refreshUser();
              ref.invalidate(tenantProfileUserProvider);
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext, true);
              }
            } catch (error) {
              if (sheetContext.mounted) {
                setSheetState(() => saving = false);
                _showSheetError(sheetContext, _profileErrorMessage(error));
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chỉnh sửa hồ sơ',
                          style: AppTextStyles.titleLg,
                        ),
                      ),
                      IconButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        _buildAvatar(
                          UserResponse(
                            username: user.username,
                            fullName: user.fullName,
                            avatarData: avatarData,
                          ),
                          88,
                          backgroundColor: Theme.of(
                            sheetContext,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          textColor: Theme.of(sheetContext).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: saving ? null : chooseAvatar,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Chọn ảnh'),
                            ),
                            if (avatarData != null)
                              TextButton.icon(
                                onPressed: saving
                                    ? null
                                    : () => setSheetState(() {
                                        avatarData = null;
                                        avatarChanged = true;
                                      }),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Xoá ảnh'),
                              ),
                          ],
                        ),
                        Text(
                          'PNG, JPEG hoặc WebP · tối đa 2 MB',
                          style: AppTextStyles.bodySm.copyWith(
                            color: Theme.of(
                              sheetContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: phoneCtrl,
                    enabled: !saving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    enabled: !saving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      helperText: originalEmail.isEmpty
                          ? 'Tài khoản chưa có email: email mới được thêm trực tiếp.'
                          : 'Đổi email hiện tại cần nhập mã OTP gửi đến email mới.',
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: addressCtrl,
                    enabled: !saving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ thường trú *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    if (saved != true || !context.mounted) return;

    if (emailStart?.requiresVerification == true) {
      await _showEmailOtpDialog(context, ref, emailStart!.email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin cá nhân.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showEmailOtpDialog(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final codeCtrl = TextEditingController();
    String? errorText;
    bool verifying = false;
    bool resending = false;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> verifyCode() async {
            final code = codeCtrl.text.trim();
            if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
              setDialogState(() => errorText = 'Vui lòng nhập đúng 6 chữ số.');
              return;
            }
            setDialogState(() {
              verifying = true;
              errorText = null;
            });
            try {
              await TenantRepository.instance.verifyEmailChange(
                email: email,
                code: code,
              );
              await ref.read(authControllerProvider.notifier).refreshUser();
              ref.invalidate(tenantProfileUserProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } catch (error) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  verifying = false;
                  errorText = _profileErrorMessage(error);
                });
              }
            }
          }

          Future<void> resend() async {
            setDialogState(() {
              resending = true;
              errorText = null;
            });
            try {
              await TenantRepository.instance.requestEmailChange(email);
              if (dialogContext.mounted) {
                setDialogState(() => resending = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Đã gửi lại mã xác minh.')),
                );
              }
            } catch (error) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  resending = false;
                  errorText = _profileErrorMessage(error);
                });
              }
            }
          }

          return AlertDialog(
            title: const Text('Xác minh email mới'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã OTP 6 chữ số đã được gửi tới $email.'),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  enabled: !verifying,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Mã xác minh',
                    prefixIcon: const Icon(Icons.password_outlined),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => verifying ? null : verifyCode(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: verifying
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Để sau'),
              ),
              TextButton(
                onPressed: verifying || resending ? null : resend,
                child: Text(resending ? 'Đang gửi...' : 'Gửi lại mã'),
              ),
              FilledButton(
                onPressed: verifying ? null : verifyCode,
                child: Text(verifying ? 'Đang xác minh...' : 'Xác nhận'),
              ),
            ],
          );
        },
      ),
    );

    codeCtrl.dispose();
    if (verified == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email mới đã được xác minh và cập nhật.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showSheetError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  String _profileErrorMessage(Object error) {
    if (error is ApiException) {
      return switch (error.errorCode) {
        'USER_PHONE_EXISTS' => 'Số điện thoại đã được tài khoản khác sử dụng.',
        'USER_EMAIL_EXISTS' => 'Email đã được tài khoản khác sử dụng.',
        'EMAIL_CHANGE_CODE_INVALID' => 'Mã xác minh không chính xác.',
        'EMAIL_CHANGE_CODE_EXPIRED' =>
          'Mã xác minh đã hết hạn. Vui lòng gửi lại mã.',
        'EMAIL_CHANGE_TOO_MANY_ATTEMPTS' =>
          'Bạn đã nhập sai quá nhiều lần. Vui lòng gửi mã mới.',
        'EMAIL_CHANGE_MAIL_NOT_CONFIGURED' =>
          'Dịch vụ gửi email chưa được cấu hình.',
        'PROFILE_AVATAR_TOO_LARGE' => 'Ảnh đại diện không được vượt quá 2 MB.',
        _ => error.message,
      };
    }
    return 'Không thể cập nhật hồ sơ. Vui lòng thử lại.';
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.outline, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
