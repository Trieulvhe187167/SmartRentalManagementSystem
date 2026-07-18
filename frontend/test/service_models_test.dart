import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/service_models.dart';

void main() {
  test('metered service keeps service type and charge type separate', () {
    final service = ServiceItem.fromJson(const {
      'id': 1,
      'code': 'ELECTRICITY',
      'name': 'Điện',
      'type': 'ELECTRICITY',
      'chargeType': 'METERED',
      'unit': 'kWh',
      'status': 'ACTIVE',
      'active': true,
    });

    expect(service.type, 'ELECTRICITY');
    expect(service.chargeType, 'METERED');
    expect(service.isMetered, isTrue);
  });

  test('service creation includes its initial price and effective date', () {
    const request = ServiceRequest(
      name: 'Rác',
      code: 'CLEANING',
      type: 'CLEANING',
      unit: 'tháng',
      chargeType: 'FIXED_PER_ROOM',
      active: true,
      initialUnitPrice: 30000,
      priceEffectiveFrom: '2026-07-19',
    );

    expect(request.toJson()['initialUnitPrice'], 30000);
    expect(request.toJson()['priceEffectiveFrom'], '2026-07-19');
  });
}
