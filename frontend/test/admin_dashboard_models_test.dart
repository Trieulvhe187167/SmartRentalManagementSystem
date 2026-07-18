import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/admin_models.dart';

void main() {
  test('admin dashboard maps monthly debt separately from total debt', () {
    final response = AdminDashboardResponse.fromJson({
      'monthlyInvoiceAmount': 5000,
      'monthlyCollectedAmount': 3500,
      'monthlyDebtAmount': 1500,
      'totalDebt': 2200,
    });

    expect(response.monthlyRevenue, 5000);
    expect(response.currentMonthRevenue, 3500);
    expect(response.currentMonthDebt, 1500);
    expect(response.totalDebt, 2200);
  });
}
