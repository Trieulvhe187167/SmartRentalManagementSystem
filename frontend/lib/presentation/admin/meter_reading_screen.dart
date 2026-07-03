import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/meter_reading_models.dart';
import '../../data/models/room_models.dart';
import '../../data/models/service_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/loading_shimmer.dart';

final adminRoomsListProvider = FutureProvider<List<Room>>((ref) async {
  final res = await AdminRepository.instance.rooms(size: 100);
  return res.content;
});

final meteredServicesProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final services = await AdminRepository.instance.services(activeOnly: true);
  return services.where((service) => service.type == 'METERED').toList();
});

final latestReadingProvider =
    FutureProvider.family.autoDispose<MeterReading?, (int roomId, int serviceId)>((ref, arg) async {
  try {
    final reading = await AdminRepository.instance.latestRoomReading(
      arg.$1,
      serviceId: arg.$2,
    );
    return reading;
  } catch (_) {
    return null;
  }
});

class AdminMeterReadingScreen extends ConsumerStatefulWidget {
  const AdminMeterReadingScreen({super.key});

  @override
  ConsumerState<AdminMeterReadingScreen> createState() => _AdminMeterReadingScreenState();
}

class _AdminMeterReadingScreenState extends ConsumerState<AdminMeterReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prevCtrl = TextEditingController();
  final _currCtrl = TextEditingController();

  int? _selectedRoomId;
  int? _selectedServiceId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime _readingDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _prevCtrl.dispose();
    _currCtrl.dispose();
    super.dispose();
  }

  void _onRoomOrServiceChanged(int? roomId, int? serviceId) async {
    if (roomId == null || serviceId == null) return;
    // trigger auto fetch for previous reading
    ref.invalidate(latestReadingProvider((roomId, serviceId)));
    final latest = await ref.read(latestReadingProvider((roomId, serviceId)).future);
    if (latest != null) {
      _prevCtrl.text = (latest.currentReading ?? 0.0).toStringAsFixed(1);
    } else {
      _prevCtrl.text = '0.0';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn phòng'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn loại chỉ số'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _submitting = true);

    final req = MeterReadingRequest(
      roomId: _selectedRoomId!,
      serviceId: _selectedServiceId!,
      billingMonth: _selectedMonth,
      billingYear: _selectedYear,
      previousReading: double.tryParse(_prevCtrl.text.trim()) ?? 0.0,
      currentReading: double.tryParse(_currCtrl.text.trim()) ?? 0.0,
      readingDate: _readingDate.toIso8601String().substring(0, 10),
    );

    try {
      await AdminRepository.instance.createMeterReading(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhập chỉ số thành công!'), backgroundColor: AppColors.success),
        );
        _currCtrl.clear();
        _onRoomOrServiceChanged(_selectedRoomId, _selectedServiceId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(adminRoomsListProvider);
    final servicesAsync = ref.watch(meteredServicesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nhập điện nước'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Thông tin ghi nhận chỉ số', style: AppTextStyles.titleMd),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Dropdown
                    roomsAsync.when(
                      data: (rooms) => DropdownButtonFormField<int>(
                        value: _selectedRoomId,
                        decoration: const InputDecoration(
                          labelText: 'Chọn phòng',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                        items: rooms.map((r) {
                          return DropdownMenuItem(value: r.id, child: Text('Phòng ${r.roomNumber}'));
                        }).toList(),
                        onChanged: (id) {
                          setState(() => _selectedRoomId = id);
                          _onRoomOrServiceChanged(id, _selectedServiceId);
                        },
                      ),
                      loading: () => const LoadingShimmer(height: 52),
                      error: (e, _) => Text('Lỗi tải phòng: $e'),
                    ),
                    const SizedBox(height: 16),

                    servicesAsync.when(
                      data: (services) {
                        if (_selectedServiceId == null && services.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _selectedServiceId == null) {
                              setState(() => _selectedServiceId = services.first.id);
                              _onRoomOrServiceChanged(_selectedRoomId, services.first.id);
                            }
                          });
                        }
                        return DropdownButtonFormField<int>(
                          value: _selectedServiceId,
                      decoration: const InputDecoration(labelText: 'Loại chỉ số'),
                          items: services.map((service) {
                            final unit = service.unit == null ? '' : ' (${service.unit})';
                            return DropdownMenuItem(
                              value: service.id,
                              child: Text('${service.name ?? service.code ?? 'Dịch vụ'}$unit'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedServiceId = v);
                              _onRoomOrServiceChanged(_selectedRoomId, v);
                            }
                          },
                        );
                      },
                      loading: () => const LoadingShimmer(height: 52),
                      error: (e, _) => Text('Lỗi tải dịch vụ: $e'),
                    ),
                    const SizedBox(height: 16),

                    // Month & Year Selector
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(labelText: 'Tháng'),
                            items: List.generate(12, (i) {
                              return DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'));
                            }),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedMonth = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: const InputDecoration(labelText: 'Năm'),
                            items: [
                              DropdownMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}')),
                              DropdownMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}')),
                              DropdownMenuItem(value: DateTime.now().year + 1, child: Text('${DateTime.now().year + 1}')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedYear = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Readings Inputs
              Text('Chỉ số đo đạc', style: AppTextStyles.titleMd),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    // Previous Reading
                    TextFormField(
                      controller: _prevCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chỉ số cũ',
                        prefixIcon: Icon(Icons.history_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập chỉ số cũ' : null,
                    ),
                    const SizedBox(height: 16),

                    // Current Reading
                    TextFormField(
                      controller: _currCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chỉ số mới',
                        prefixIcon: Icon(Icons.speed_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập chỉ số mới';
                        final prev = double.tryParse(_prevCtrl.text) ?? 0.0;
                        final curr = double.tryParse(v) ?? 0.0;
                        if (curr < prev) return 'Chỉ số mới không được nhỏ hơn chỉ số cũ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Input
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _readingDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _readingDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày chốt số',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DateFormatter.format(_readingDate)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Ghi nhận chỉ số'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
