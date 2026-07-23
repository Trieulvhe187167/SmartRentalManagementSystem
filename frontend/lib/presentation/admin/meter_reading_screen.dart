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
  return services.where((service) => service.isMetered).toList();
});

final latestReadingProvider = FutureProvider.family
    .autoDispose<MeterReading?, (int roomId, int serviceId)>((ref, arg) async {
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
  ConsumerState<AdminMeterReadingScreen> createState() =>
      _AdminMeterReadingScreenState();
}

class _AdminMeterReadingScreenState
    extends ConsumerState<AdminMeterReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _electricPrevCtrl = TextEditingController();
  final _electricCurrCtrl = TextEditingController();
  final _waterPrevCtrl = TextEditingController();
  final _waterCurrCtrl = TextEditingController();

  int? _selectedRoomId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime _readingDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _electricPrevCtrl.dispose();
    _electricCurrCtrl.dispose();
    _waterPrevCtrl.dispose();
    _waterCurrCtrl.dispose();
    super.dispose();
  }

  ServiceItem _serviceByCode(List<ServiceItem> services, String code) {
    return services.firstWhere(
      (service) => service.code?.toUpperCase() == code,
      orElse: () => throw StateError('Không tìm thấy dịch vụ $code'),
    );
  }

  Future<void> _loadPreviousReadings(
    int? roomId,
    List<ServiceItem> services,
  ) async {
    if (roomId == null) return;
    final electricity = _serviceByCode(services, 'ELECTRICITY');
    final water = _serviceByCode(services, 'WATER');
    final readings = await Future.wait([
      ref.read(latestReadingProvider((roomId, electricity.id!)).future),
      ref.read(latestReadingProvider((roomId, water.id!)).future),
    ]);
    if (!mounted || roomId != _selectedRoomId) return;
    _electricPrevCtrl.text = (readings[0]?.currentReading ?? 0).toStringAsFixed(
      1,
    );
    _waterPrevCtrl.text = (readings[1]?.currentReading ?? 0).toStringAsFixed(1);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final services = await ref.read(meteredServicesProvider.future);
      final electricity = _serviceByCode(services, 'ELECTRICITY');
      final water = _serviceByCode(services, 'WATER');
      final readingDate = _readingDate.toIso8601String().substring(0, 10);

      MeterReadingRequest request(
        ServiceItem service,
        TextEditingController previous,
        TextEditingController current,
      ) => MeterReadingRequest(
        roomId: _selectedRoomId!,
        serviceId: service.id!,
        billingMonth: _selectedMonth,
        billingYear: _selectedYear,
        previousReading: double.parse(previous.text.trim()),
        currentReading: double.parse(current.text.trim()),
        readingDate: readingDate,
      );

      await Future.wait([
        AdminRepository.instance.createMeterReading(
          request(electricity, _electricPrevCtrl, _electricCurrCtrl),
        ),
        AdminRepository.instance.createMeterReading(
          request(water, _waterPrevCtrl, _waterCurrCtrl),
        ),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nhập chỉ số điện và nước thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        _electricCurrCtrl.clear();
        _waterCurrCtrl.clear();
        _loadPreviousReadings(_selectedRoomId, services);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _readingInputs({
    required String title,
    required String? unit,
    required IconData icon,
    required TextEditingController previous,
    required TextEditingController current,
  }) {
    String? validateNumber(String? value, String label) {
      if (value == null || value.trim().isEmpty) {
        return 'Vui lòng nhập $label';
      }
      if (double.tryParse(value.trim()) == null) {
        return '$label không hợp lệ';
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.titleMd),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: previous,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Chỉ số $title cũ',
            suffixText: unit,
            prefixIcon: const Icon(Icons.history_outlined),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => validateNumber(value, 'chỉ số cũ'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: current,
          decoration: InputDecoration(
            labelText: 'Chỉ số $title mới',
            suffixText: unit,
            prefixIcon: const Icon(Icons.speed_outlined),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final error = validateNumber(value, 'chỉ số mới');
            if (error != null) return error;
            final oldValue = double.tryParse(previous.text.trim()) ?? 0;
            final newValue = double.parse(value!.trim());
            if (newValue < oldValue) {
              return 'Chỉ số mới không được nhỏ hơn chỉ số cũ';
            }
            return null;
          },
        ),
      ],
    );
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
                        initialValue: _selectedRoomId,
                        decoration: const InputDecoration(
                          labelText: 'Chọn phòng',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                        items: rooms.map((r) {
                          return DropdownMenuItem(
                            value: r.id,
                            child: Text('Phòng ${r.roomNumber}'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          setState(() => _selectedRoomId = id);
                          ref.read(meteredServicesProvider.future).then((
                            services,
                          ) {
                            _loadPreviousReadings(id, services);
                          });
                        },
                      ),
                      loading: () => const LoadingShimmer(height: 52),
                      error: (e, _) => Text('Lỗi tải phòng: $e'),
                    ),
                    const SizedBox(height: 16),

                    // Month & Year Selector
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Tháng',
                            ),
                            items: List.generate(12, (i) {
                              return DropdownMenuItem(
                                value: i + 1,
                                child: Text('Tháng ${i + 1}'),
                              );
                            }),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedMonth = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            decoration: const InputDecoration(labelText: 'Năm'),
                            items: [
                              DropdownMenuItem(
                                value: DateTime.now().year - 1,
                                child: Text('${DateTime.now().year - 1}'),
                              ),
                              DropdownMenuItem(
                                value: DateTime.now().year,
                                child: Text('${DateTime.now().year}'),
                              ),
                              DropdownMenuItem(
                                value: DateTime.now().year + 1,
                                child: Text('${DateTime.now().year + 1}'),
                              ),
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
                child: servicesAsync.when(
                  data: (services) => Column(
                    children: [
                      _readingInputs(
                        title: 'Điện',
                        unit: _serviceByCode(services, 'ELECTRICITY').unit,
                        icon: Icons.electric_bolt_outlined,
                        previous: _electricPrevCtrl,
                        current: _electricCurrCtrl,
                      ),
                      const Divider(height: 32),
                      _readingInputs(
                        title: 'Nước',
                        unit: _serviceByCode(services, 'WATER').unit,
                        icon: Icons.water_drop_outlined,
                        previous: _waterPrevCtrl,
                        current: _waterCurrCtrl,
                      ),
                      const SizedBox(height: 20),

                      // Date Picker Input
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _readingDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
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
                  loading: () => const LoadingShimmer(height: 260),
                  error: (e, _) => Text('Lỗi tải dịch vụ: $e'),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Ghi nhận chỉ số điện và nước'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
