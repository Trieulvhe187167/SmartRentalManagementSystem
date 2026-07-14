import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/auth/login_screen.dart';

void main() {
  testWidgets('login validates required credentials before calling API', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });
}
