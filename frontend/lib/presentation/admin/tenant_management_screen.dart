import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/tenant_models.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';
import 'tenant_form_sheet.dart';

class AdminTenantManagementScreen extends ConsumerStatefulWidget {
  const AdminTenantManagementScreen({super.key});

  @override
  ConsumerState<AdminTenantManagementScreen> createState() =>
      _AdminTenantManagementScreenState();
}

class _AdminTenantManagementScreenState
    extends ConsumerState<AdminTenantManagementScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();

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
      ref.read(adminTenantsProvider.notifier).fetchTenants();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTenantsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý khách thuê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            onPressed: () => _showCreateTenantSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(adminTenantsProvider.notifier).fetchTenants(refresh: true);
        },
        child: Column(
          children: [
            // ─── Search Bar ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên hoặc số điện thoại...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(adminTenantsProvider.notifier)
                                .updateSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  ref
                      .read(adminTenantsProvider.notifier)
                      .updateSearch(v.trim());
                },
              ),
            ),

            // ─── Tenant List ─────────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          const CardShimmer(height: 100),
                    )
                  : state.error != null
                  ? ErrorState(
                      message: 'Lỗi tải danh sách khách: ${state.error}',
                      onRetry: () => ref
                          .read(adminTenantsProvider.notifier)
                          .fetchTenants(refresh: true),
                    )
                  : state.items.isEmpty
                  ? const EmptyState(
                      title: 'Không tìm thấy khách thuê nào',
                      subtitle: 'Gõ từ khóa khác hoặc bấm + để thêm khách mới',
                      icon: Icons.people_outline,
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
                        final tenant = state.items[index];
                        return _buildTenantCard(context, tenant);
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
        onPressed: () => _showCreateTenantSheet(context),
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, TenantProfile tenant) {
    final chipStatus = _tenantChipStatus(tenant);
    final chipLabel = _tenantChipLabel(tenant);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tenant.fullName ?? 'Không tên',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Chỉnh sửa thông tin',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined),
              onPressed: tenant.id == null
                  ? null
                  : () => _showEditTenantSheet(context, tenant),
            ),
            StatusChip(status: chipStatus, label: chipLabel),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.outline,
                ),
                const SizedBox(width: 6),
                Text(tenant.phone ?? '—', style: AppTextStyles.bodySm),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  size: 16,
                  color: AppColors.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  tenant.currentRoom != null
                      ? 'Phòng: ${tenant.currentRoom}'
                      : 'Chưa nhận phòng',
                  style: AppTextStyles.bodySm.copyWith(
                    color: tenant.currentRoom != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: tenant.currentRoom != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showTenantDetailSheet(context, tenant),
      ),
    );
  }

  void _showTenantDetailSheet(BuildContext context, TenantProfile tenant) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final accountStatus = tenant.userStatus?.toUpperCase();
            final canLockAccount =
                tenant.userId != null && accountStatus == 'ACTIVE';
            final canUnlockAccount =
                tenant.userId != null && accountStatus == 'LOCKED';

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tenant.fullName ?? 'Khách thuê',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineSm,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Chỉnh sửa thông tin',
                        onPressed: tenant.id == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showEditTenantSheet(rootContext, tenant);
                              },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        status: _tenantChipStatus(tenant),
                        label: _tenantChipLabel(tenant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildDetailRow('Số điện thoại', tenant.phone ?? '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Email', tenant.email ?? '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số CMND/CCCD', tenant.idNumber ?? '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Loại giấy tờ', tenant.idType ?? 'CCCD'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Địa chỉ thường trú', tenant.address ?? '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Phòng đang ở',
                    tenant.currentRoom ?? 'Chưa thuê phòng nào',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Ngày tham gia',
                    DateFormatter.format(
                      DateFormatter.tryParse(tenant.createdAt),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Tài khoản đăng nhập', style: AppTextStyles.titleSm),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tên đăng nhập', tenant.username ?? '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Trạng thái tài khoản',
                    _accountStatusLabel(tenant.userStatus),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: tenant.userId == null
                        ? null
                        : () => _showChangeUsernameDialog(context, tenant),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Đổi tên đăng nhập'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: tenant.userId == null
                        ? null
                        : () => _showResetPasswordDialog(context, tenant),
                    icon: const Icon(Icons.password_outlined),
                    label: const Text('Đặt lại mật khẩu'),
                  ),
                  if (canLockAccount) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.5,
                        ),
                      ),
                      onPressed: () => _lockTenantAccount(context, tenant),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Khóa tài khoản đăng nhập'),
                    ),
                  ] else if (canUnlockAccount) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _unlockTenantAccount(context, tenant),
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Mở khóa tài khoản'),
                    ),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: tenant.id == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            _showEditTenantSheet(rootContext, tenant);
                          },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Chỉnh sửa thông tin'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: tenant.id == null
                        ? null
                        : () async {
                            final confirmed = await _confirmTenantAction(
                              context: context,
                              title: 'Lưu trữ khách thuê',
                              message:
                                  'Khách thuê sẽ bị ẩn khỏi danh sách mặc định, nhưng lịch sử hợp đồng và hóa đơn vẫn được giữ lại.',
                              confirmLabel: 'Lưu trữ',
                            );
                            if (!confirmed || !context.mounted) return;
                            await _runTenantAction(
                              sheetContext: context,
                              tenant: tenant,
                              successMessage: 'Đã lưu trữ khách thuê',
                              action: (id) => ref
                                  .read(adminTenantsProvider.notifier)
                                  .archiveTenant(id),
                            );
                          },
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Lưu trữ khách thuê'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(
                        color: AppColors.danger,
                        width: 1.5,
                      ),
                    ),
                    onPressed: tenant.id == null
                        ? null
                        : () async {
                            final confirmed = await _confirmTenantAction(
                              context: context,
                              title: 'Xóa hồ sơ khách thuê',
                              message:
                                  'Chỉ xóa được khi khách chưa từng có hợp đồng hoặc hóa đơn. Thao tác này sẽ loại bỏ hồ sơ khách khỏi hệ thống.',
                              confirmLabel: 'Xóa hồ sơ',
                              confirmColor: AppColors.danger,
                            );
                            if (!confirmed || !context.mounted) return;
                            await _runTenantAction(
                              sheetContext: context,
                              tenant: tenant,
                              successMessage: 'Đã xóa hồ sơ khách thuê',
                              action: (id) => ref
                                  .read(adminTenantsProvider.notifier)
                                  .deleteTenant(id),
                            );
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa hồ sơ khách thuê'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTenantSheet(
    BuildContext context,
    TenantProfile tenant,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return TenantEditFormSheet(
          tenant: tenant,
          onSubmit: (req) async {
            if (tenant.id == null) return 'Khách thuê không hợp lệ';
            return ref
                .read(adminTenantsProvider.notifier)
                .updateTenant(tenant.id!, req);
          },
        );
      },
    );

    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin khách thuê thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<bool> _confirmTenantAction({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: confirmColor == null
                ? null
                : ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _runTenantAction({
    required BuildContext sheetContext,
    required TenantProfile tenant,
    required String successMessage,
    required Future<String?> Function(int id) action,
  }) async {
    if (tenant.id == null) return;
    final error = await action(tenant.id!);
    if (!sheetContext.mounted) return;
    final messenger = ScaffoldMessenger.of(sheetContext);
    Navigator.pop(sheetContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  String _accountStatusLabel(String? status) {
    return switch (status?.toUpperCase()) {
      'ACTIVE' => 'Đang hoạt động',
      'LOCKED' => 'Đang bị khóa',
      'INACTIVE' => 'Không hoạt động',
      _ => 'Chưa rõ',
    };
  }

  String _tenantChipStatus(TenantProfile tenant) {
    if (tenant.userStatus?.toUpperCase() == 'LOCKED') {
      return 'LOCKED';
    }
    if (tenant.active == false || tenant.status?.toUpperCase() == 'INACTIVE') {
      return 'INACTIVE';
    }
    return 'ACTIVE';
  }

  String _tenantChipLabel(TenantProfile tenant) {
    if (tenant.userStatus?.toUpperCase() == 'LOCKED') {
      return 'Tài khoản bị khóa';
    }
    if (tenant.active == false || tenant.status?.toUpperCase() == 'INACTIVE') {
      return 'Đã lưu trữ';
    }
    return 'Hồ sơ hoạt động';
  }

  Future<void> _showChangeUsernameDialog(
    BuildContext sheetContext,
    TenantProfile tenant,
  ) async {
    if (tenant.userId == null) return;
    final controller = TextEditingController(text: tenant.username ?? '');
    final username = await showDialog<String>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên đăng nhập'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên đăng nhập mới'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(context, value);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || !sheetContext.mounted) return;

    final messenger = ScaffoldMessenger.of(sheetContext);
    final error = await ref
        .read(adminTenantsProvider.notifier)
        .updateTenantUsername(tenant.userId!, username);
    if (!sheetContext.mounted) return;
    if (error == null) Navigator.pop(sheetContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã đổi tên đăng nhập'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _showResetPasswordDialog(
    BuildContext sheetContext,
    TenantProfile tenant,
  ) async {
    if (tenant.userId == null) return;
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final password = await showDialog<String>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu tạm thời',
                ),
                validator: _passwordValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                ),
                validator: (value) {
                  if (value != passwordCtrl.text) {
                    return 'Mật khẩu nhập lại không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, passwordCtrl.text);
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    if (password == null || !sheetContext.mounted) return;

    final messenger = ScaffoldMessenger.of(sheetContext);
    final error = await ref
        .read(adminTenantsProvider.notifier)
        .resetTenantPassword(tenant.userId!, password);
    if (!sheetContext.mounted) return;
    if (error == null) Navigator.pop(sheetContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã đặt lại mật khẩu tạm thời'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.length < 8 || password.length > 72) {
      return 'Mật khẩu phải từ 8 đến 72 ký tự';
    }
    if (!RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Mật khẩu cần có chữ và số';
    }
    return null;
  }

  Future<void> _unlockTenantAccount(
    BuildContext sheetContext,
    TenantProfile tenant,
  ) async {
    if (tenant.userId == null) return;
    final confirmed = await _confirmTenantAction(
      context: sheetContext,
      title: 'Mở khóa tài khoản',
      message: 'Khách thuê sẽ đăng nhập lại được vào ứng dụng.',
      confirmLabel: 'Mở khóa',
    );
    if (!confirmed || !sheetContext.mounted) return;
    final messenger = ScaffoldMessenger.of(sheetContext);
    final error = await ref
        .read(adminTenantsProvider.notifier)
        .unlockTenantAccount(tenant.userId!);
    if (!sheetContext.mounted) return;
    if (error == null) Navigator.pop(sheetContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã mở khóa tài khoản'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _lockTenantAccount(
    BuildContext sheetContext,
    TenantProfile tenant,
  ) async {
    if (tenant.userId == null) return;
    final confirmed = await _confirmTenantAction(
      context: sheetContext,
      title: 'Khóa tài khoản đăng nhập',
      message:
          'Khách thuê sẽ không thể đăng nhập vào ứng dụng cho đến khi admin mở khóa lại.',
      confirmLabel: 'Khóa tài khoản',
      confirmColor: AppColors.danger,
    );
    if (!confirmed || !sheetContext.mounted) return;
    final messenger = ScaffoldMessenger.of(sheetContext);
    final error = await ref
        .read(adminTenantsProvider.notifier)
        .lockTenantAccount(tenant.userId!);
    if (!sheetContext.mounted) return;
    if (error == null) Navigator.pop(sheetContext);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã khóa tài khoản đăng nhập'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showCreateTenantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CreateTenantForm(
          onSubmit: (req) async {
            final error = await ref
                .read(adminTenantsProvider.notifier)
                .createTenant(req);
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
                    content: Text('Thêm khách thuê mới thành công'),
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

class _CreateTenantForm extends StatefulWidget {
  final Function(TenantRequest req) onSubmit;

  const _CreateTenantForm({required this.onSubmit});

  @override
  State<_CreateTenantForm> createState() => _CreateTenantFormState();
}

class _CreateTenantFormState extends State<_CreateTenantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idNoCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _idType = 'CCCD';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _idNoCtrl.dispose();
    _addrCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
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
              Text('Thêm khách thuê mới', style: AppTextStyles.headlineSm),
              const SizedBox(height: 20),

              // Full name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên khách thuê',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập họ tên'
                    : null,
              ),
              const SizedBox(height: 16),

              // Phone & Email row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nhập SĐT' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nhập email' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ID number & Type row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số CMND/CCCD',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập số CMND'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _idType,
                      decoration: const InputDecoration(
                        labelText: 'Loại giấy tờ',
                      ),
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

              // Address
              TextFormField(
                controller: _addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ thường trú',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nhập địa chỉ thường trú'
                    : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Text('Tạo tài khoản liên kết', style: AppTextStyles.titleSm),
              const SizedBox(height: 16),

              // Username & Password row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nhập username'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                        if (v.length < 8) return 'Tối thiểu 8 ký tự';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit(
                        TenantRequest(
                          fullName: _nameCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          idNumber: _idNoCtrl.text.trim(),
                          idType: _idType,
                          address: _addrCtrl.text.trim(),
                          username: _userCtrl.text.trim(),
                          password: _passCtrl.text,
                        ),
                      );
                    }
                  },
                  child: const Text('Thêm khách hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
