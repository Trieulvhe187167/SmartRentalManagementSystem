import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/contract_models.dart';

void main() {
  test('maps a contract awaiting tenant confirmation', () {
    final contract = RentalContract.fromJson({
      'id': 12,
      'contractCode': 'HD-2026-012',
      'room': {'roomNumber': '305'},
      'primaryTenant': {'id': 7, 'fullName': 'Nguyễn Minh Anh'},
      'startDate': '2026-08-01',
      'endDate': '2027-07-31',
      'appliedRent': 3500000,
      'depositAmount': 3500000,
      'monthlyDueDay': 5,
      'status': 'PENDING_CONFIRMATION',
      'terms': 'Thanh toán trước ngày 5 hàng tháng.',
      'currentOccupantCount': 1,
    });

    expect(contract.id, 12);
    expect(contract.roomNumber, '305');
    expect(contract.tenantProfileId, 7);
    expect(contract.monthlyDueDay, 5);
    expect(contract.currentOccupantCount, 1);
    expect(contract.isPendingConfirmation, isTrue);
    expect(contract.isActive, isFalse);
  });

  test('maps tenant rejection details', () {
    final contract = RentalContract.fromJson({
      'id': 13,
      'status': 'REJECTED',
      'tenantRejectedAt': '2026-07-19T18:00:00',
      'tenantRejectionReason': 'Tiền cọc chưa đúng.',
    });

    expect(contract.tenantRejectedAt, isNotNull);
    expect(contract.tenantRejectionReason, 'Tiền cọc chưa đúng.');
    expect(contract.isPendingConfirmation, isFalse);
  });

  test('future contract occupant is not counted as currently active', () {
    final occupant = ContractOccupant.fromJson({
      'relationshipToPrimary': 'Bạn',
      'moveInDate': '2099-01-01',
      'occupant': {'id': 8, 'fullName': 'Nguyễn Văn B'},
    });

    expect(occupant.isActive, isFalse);
    expect(occupant.hasMovedOut, isFalse);
  });
}
