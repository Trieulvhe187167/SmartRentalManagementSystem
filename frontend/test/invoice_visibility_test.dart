import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/invoice_models.dart';
import 'package:frontend/data/models/tenant_models.dart';

void main() {
  test('draft and cancelled invoices are hidden from tenants', () {
    final draft = Invoice.fromJson(const {'status': 'DRAFT'});
    final cancelled = Invoice.fromJson(const {'status': 'CANCELLED'});
    final issued = Invoice.fromJson(const {'status': 'ISSUED'});
    final paid = Invoice.fromJson(const {'status': 'PAID'});

    expect(draft.isVisibleToTenant, isFalse);
    expect(cancelled.isVisibleToTenant, isFalse);
    expect(issued.isVisibleToTenant, isTrue);
    expect(paid.isVisibleToTenant, isTrue);
  });

  test('tenant dashboard discards a draft current invoice', () {
    final dashboard = TenantDashboardResponse.fromJson(const {
      'latestInvoice': {'id': 99, 'status': 'DRAFT'},
    });

    expect(dashboard.currentInvoice, isNull);
  });

  test('tenant dashboard keeps an issued current invoice', () {
    final dashboard = TenantDashboardResponse.fromJson(const {
      'latestInvoice': {'id': 10, 'status': 'ISSUED'},
    });

    expect(dashboard.currentInvoice?.id, 10);
  });
}
