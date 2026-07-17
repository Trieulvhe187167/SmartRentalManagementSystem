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
}
