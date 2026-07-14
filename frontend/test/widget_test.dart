import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/password_validator.dart';
import 'package:frontend/data/api/api_client.dart';
import 'package:frontend/presentation/auth/reset_password_screen.dart';

void main() {
  group('PasswordValidator', () {
    test('accepts a strong password', () {
      expect(PasswordValidator.validateNewPassword('MatKhau123'), isNull);
    });

    test('rejects weak and reused passwords', () {
      expect(PasswordValidator.validateNewPassword('OnlyLetters'), isNotNull);
      expect(
        PasswordValidator.validateNewPassword(
          'Current123',
          currentPassword: 'Current123',
        ),
        isNotNull,
      );
    });
  });

  test('auth session notifier emits an expiration event', () {
    final notifier = AuthSessionNotifier();
    var notifications = 0;
    notifier.addListener(() => notifications++);

    notifier.sessionExpired();

    expect(notifications, 1);
  });

  testWidgets('reset screen never displays the token', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResetPasswordScreen(initialToken: 'secret-reset-token'),
        ),
      ),
    );

    expect(find.text('Mã xác nhận'), findsNothing);
    expect(find.textContaining('secret-reset-token'), findsNothing);
    expect(find.text('Mật khẩu mới'), findsOneWidget);
  });

  testWidgets('reset screen rejects a link without a token', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())),
    );

    expect(find.text('Liên kết đặt lại mật khẩu không hợp lệ'), findsOneWidget);
    expect(find.text('Mã xác nhận'), findsNothing);
  });
}
