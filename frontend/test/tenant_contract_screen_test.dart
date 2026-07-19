import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/contract_models.dart';
import 'package:frontend/presentation/tenant/contract_screen.dart';
import 'package:frontend/presentation/tenant/tenant_controller.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  testWidgets('pending contract shows tenant confirmation actions', (
    tester,
  ) async {
    const contract = RentalContract(
      id: 21,
      contractNumber: 'HD-2026-021',
      roomNumber: '305',
      startDate: '2026-08-01',
      endDate: '2027-07-31',
      monthlyRent: 3500000,
      deposit: 3500000,
      monthlyDueDay: 5,
      status: 'PENDING_CONFIRMATION',
      notes: 'Thanh toán trước ngày 5 hàng tháng.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantContractProvider.overrideWith((ref) async => contract),
        ],
        child: const MaterialApp(home: TenantContractScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hợp đồng mới'), findsOneWidget);
    expect(find.text('Chờ khách xác nhận'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tôi đã đọc, hiểu và đồng ý với nội dung hợp đồng.'),
      300,
    );

    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
    expect(
      find.text('Tôi đã đọc, hiểu và đồng ý với nội dung hợp đồng.'),
      findsOneWidget,
    );
  });
}
