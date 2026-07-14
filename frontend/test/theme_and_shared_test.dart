import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:frontend/presentation/shared/widgets/app_card.dart';
import 'package:frontend/presentation/shared/widgets/empty_state.dart';
import 'package:frontend/presentation/shared/widgets/loading_shimmer.dart';
import 'package:frontend/presentation/shared/widgets/status_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme mode is restored and persisted', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    final restored = await ThemeModeNotifier.loadSavedThemeMode();
    expect(restored, ThemeMode.dark);

    final notifier = ThemeModeNotifier(initialMode: restored);
    await notifier.setThemeMode(ThemeMode.light);
    final preferences = await SharedPreferences.getInstance();

    expect(notifier.state, ThemeMode.light);
    expect(preferences.getString('theme_mode'), 'light');
  });

  for (final entry in <String, Brightness>{
    'light': Brightness.light,
    'dark': Brightness.dark,
  }.entries) {
    testWidgets('shared widgets render in ${entry.key} mode', (tester) async {
      final theme = entry.value == Brightness.dark
          ? AppTheme.dark
          : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const AppCard(
                    title: 'Thẻ dùng chung',
                    trailing: Icon(Icons.chevron_right),
                    child: Text('Nội dung'),
                  ),
                  const StatusChip(status: 'PAID'),
                  const PriorityChip(priority: 'HIGH'),
                  const EmptyState(
                    title: 'Không có dữ liệu',
                    subtitle: 'Hãy thử lại sau',
                  ),
                  const ErrorState(message: 'Không tải được dữ liệu'),
                  const LoadingShimmer(width: 120),
                  const CardShimmer(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final contentContext = tester.element(find.text('Nội dung'));
      expect(
        Theme.of(contentContext).brightness,
        entry.key == 'dark' ? Brightness.dark : Brightness.light,
      );
      expect(find.text('Đã thanh toán'), findsOneWidget);
      expect(find.text('Khẩn cấp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
