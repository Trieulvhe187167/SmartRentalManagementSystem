import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Status chip (pill-shaped) with color derived from status string
class StatusChip extends StatelessWidget {
  final String status;
  final String? label;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.status,
    this.label,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final text = label ?? _vietnameseLabel(status);
    final semanticColor = AppColors.statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Color.lerp(semanticColor, Colors.white, 0.3)!
        : semanticColor;
    final bgColor = isDark
        ? Color.alphaBlend(
            color.withAlpha(36),
            Theme.of(context).colorScheme.surface,
          )
        : AppColors.statusLightColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelMd.copyWith(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _vietnameseLabel(String status) {
    return switch (status.toUpperCase()) {
      'PAID' => 'Đã thanh toán',
      'PARTIALLY_PAID' => 'Thanh toán một phần',
      'ISSUED' => 'Đã phát hành',
      'DRAFT' => 'Nháp',
      'OVERDUE' => 'Quá hạn',
      'CANCELLED' => 'Đã hủy',
      'ACTIVE' => 'Đang hiệu lực',
      'LOCKED' => 'Đang bị khóa',
      'INACTIVE' => 'Không hoạt động',
      'EXPIRED' => 'Hết hạn',
      'TERMINATED' => 'Đã chấm dứt',
      'PENDING_APPROVAL' => 'Chờ duyệt',
      'AVAILABLE' => 'Trống',
      'OCCUPIED' => 'Đã thuê',
      'MAINTENANCE' => 'Bảo trì',
      'PENDING' => 'Đang chờ',
      'OPEN' => 'Đang chờ',
      'RECEIVED' => 'Đã tiếp nhận',
      'IN_PROGRESS' => 'Đang xử lý',
      'RESOLVED' => 'Đã xử lý',
      'REJECTED' => 'Đã từ chối',
      'CONFIRMED' => 'Đã xác nhận',
      _ => status,
    };
  }
}

/// Priority chip for maintenance requests
class PriorityChip extends StatelessWidget {
  final String priority;
  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (text, semanticColor, lightBackground) = switch (priority
        .toUpperCase()) {
      'HIGH' ||
      'URGENT' => ('Khẩn cấp', AppColors.danger, AppColors.dangerLight),
      'MEDIUM' ||
      'NORMAL' => ('Bình thường', AppColors.warning, AppColors.warningLight),
      _ => ('Thấp', AppColors.neutral, AppColors.neutralLight),
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Color.lerp(semanticColor, Colors.white, 0.3)!
        : semanticColor;
    final bgColor = isDark
        ? Color.alphaBlend(
            color.withAlpha(36),
            Theme.of(context).colorScheme.surface,
          )
        : lightBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
