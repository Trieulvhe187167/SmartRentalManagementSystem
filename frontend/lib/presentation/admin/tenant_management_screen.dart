import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/tenant_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import 'admin_controller.dart';

class AdminTenantManagementScreen extends ConsumerStatefulWidget {
  const AdminTenantManagementScreen({super.key});

  @override
  ConsumerState<AdminTenantManagementScreen> createState() => _AdminTenantManagementScreenState();
}

class _AdminTenantManagementScreenState extends ConsumerState<AdminTenantManagementScreen> {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
                            ref.read(adminTenantsProvider.notifier).updateSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  ref.read(adminTenantsProvider.notifier).updateSearch(v.trim());
                },
              ),
            ),

            // ─── Tenant List ─────────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 5,
                      itemBuilder: (context, index) => const CardShimmer(height: 100),
                    )
                  : state.error != null
                      ? ErrorState(
                          message: 'Lỗi tải danh sách khách: ${state.error}',
                          onRetry: () => ref.read(adminTenantsProvider.notifier).fetchTenants(refresh: true),
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
                              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
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
    final active = tenant.active ?? false;

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
            Text(
              tenant.fullName ?? 'Không tên',
              style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
            ),
            StatusChip(status: active ? 'ACTIVE' : 'EXPIRED', label: active ? 'Hoạt động' : 'Tạm ngưng'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.outline),
                const SizedBox(width: 6),
                Text(tenant.phone ?? '—', style: AppTextStyles.bodySm),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.outline),
                const SizedBox(width: 6),
                Text(
                  tenant.currentRoom != null ? 'Phòng: ${tenant.currentRoom}' : 'Chưa nhận phòng',
                  style: AppTextStyles.bodySm.copyWith(
                    color: tenant.currentRoom != null ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: tenant.currentRoom != null ? FontWeight.bold : FontWeight.normal,
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
                      Text(tenant.fullName ?? 'Khách thuê', style: AppTextStyles.headlineSm),
                      StatusChip(status: (tenant.active ?? false) ? 'ACTIVE' : 'EXPIRED', label: (tenant.active ?? false) ? 'Hoạt động' : 'Tạm ngưng'),
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
                  _buildDetailRow('Phòng đang ở', tenant.currentRoom ?? 'Chưa thuê phòng nào'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Ngày tham gia', DateFormatter.format(DateFormatter.tryParse(tenant.createdAt))),
                  const SizedBox(height: 32),
                  if (tenant.active ?? false)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                      onPressed: () async {
                        try {
                          await AdminRepository.instance.deactivateTenant(tenant.id!);
                          ref.read(adminTenantsProvider.notifier).fetchTenants(refresh: true);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tạm ngưng tài khoản khách thành công'), backgroundColor: AppColors.success),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('Tạm khóa khách thuê này'),
                    ),
                ],
              ),
            );
          },
        );
      },
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
            style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            final error = await ref.read(adminTenantsProvider.notifier).createTenant(req);
            if (context.mounted) {
              Navigator.pop(context);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: AppColors.error),
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
                decoration: const InputDecoration(labelText: 'Họ và tên khách thuê'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),

              // Phone & Email row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập SĐT' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập email' : null,
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
                      decoration: const InputDecoration(labelText: 'Số CMND/CCCD'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập số CMND' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _idType,
                      decoration: const InputDecoration(labelText: 'Loại giấy tờ'),
                      items: const [
                        DropdownMenuItem(value: 'CCCD', child: Text('CCCD')),
                        DropdownMenuItem(value: 'CMND', child: Text('CMND')),
                        DropdownMenuItem(value: 'PASSPORT', child: Text('Hộ chiếu')),
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
                decoration: const InputDecoration(labelText: 'Địa chỉ thường trú'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập địa chỉ thường trú' : null,
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
                      decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập username' : null,
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
