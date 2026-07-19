import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/auth_models.dart';

void main() {
  test('user response maps avatar data', () {
    final user = UserResponse.fromJson(const {
      'id': 7,
      'username': 'tenant01',
      'avatarData': 'data:image/png;base64,aGVsbG8=',
    });

    expect(user.avatarData, 'data:image/png;base64,aGVsbG8=');
  });

  test('profile update omits avatar when it is unchanged', () {
    const request = TenantProfileUpdateRequest(
      phone: '0901000001',
      permanentAddress: 'Thành phố Thủ Đức',
    );

    expect(request.toJson().containsKey('avatarData'), isFalse);
  });

  test('email change response indicates whether otp is required', () {
    final response = EmailChangeStartResponse.fromJson(const {
      'requiresVerification': true,
      'email': 'new@example.com',
      'message': 'Verification code was sent',
    });

    expect(response.requiresVerification, isTrue);
    expect(response.email, 'new@example.com');
  });
}
