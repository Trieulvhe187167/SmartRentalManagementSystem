import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class NetworkErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const NetworkErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.outline),
                ),
                const SizedBox(height: 24),
                Text('Mất kết nối mạng', style: AppTextStyles.headlineSm, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet và thử lại.',
                  style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
