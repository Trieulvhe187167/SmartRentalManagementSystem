import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/admin_models.dart';
import 'package:frontend/data/models/invoice_models.dart';

void main() {
  test('monthly revenue maps real invoice and payment totals', () {
    final data = MonthlyRevenueData.fromJson({
      'month': 7,
      'year': 2026,
      'totalRevenue': 12000000,
      'collectedRevenue': 9000000,
      'debtAmount': 3000000,
      'invoiceCount': 8,
      'paidInvoiceCount': 6,
    });

    expect(data.month, 7);
    expect(data.totalRevenue, 12000000);
    expect(data.collectedRevenue, 9000000);
    expect(data.debtAmount, 3000000);
    expect(data.invoiceCount, 8);
    expect(data.paidInvoiceCount, 6);
  });

  test('invoice item maps backend itemType and unit fields', () {
    final item = InvoiceItem.fromJson({
      'id': 10,
      'itemType': 'METERED_SERVICE',
      'description': 'Tiền điện',
      'quantity': 15,
      'unitPrice': 3500,
      'amount': 52500,
      'unit': 'kWh',
    });

    expect(item.type, 'METERED_SERVICE');
    expect(item.unit, 'kWh');
    expect(item.amount, 52500);
  });

  test('invoice cancellation sends the required audit reason', () {
    const request = InvoiceCancelRequest(reason: 'Sai chỉ số điện');

    expect(request.toJson(), {'cancellationReason': 'Sai chỉ số điện'});
  });
}
