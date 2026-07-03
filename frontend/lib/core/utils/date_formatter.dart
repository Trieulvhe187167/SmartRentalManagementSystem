import 'package:intl/intl.dart';

/// Date/time formatter utilities (Vietnamese locale)
class DateFormatter {
  DateFormatter._();

  static final _dateFormatter = DateFormat('dd/MM/yyyy', 'vi_VN');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
  static final _monthYearFormatter = DateFormat('MM/yyyy', 'vi_VN');
  static final _timeFormatter = DateFormat('HH:mm', 'vi_VN');
  static final _shortDateFormatter = DateFormat("dd 'thg' MM", 'vi_VN');
  static final _dayMonthYearFormatter = DateFormat("dd 'tháng' MM, yyyy", 'vi_VN');

  /// Format: 25/06/2026
  static String format(DateTime? date) {
    if (date == null) return '—';
    return _dateFormatter.format(date);
  }

  /// Format: 25/06/2026 14:30
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return _dateTimeFormatter.format(date);
  }

  /// Format: 06/2026
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '—';
    return _monthYearFormatter.format(date);
  }

  /// Format: 14:30
  static String formatTime(DateTime? date) {
    if (date == null) return '—';
    return _timeFormatter.format(date);
  }

  /// Format: 25 thg 6
  static String formatShort(DateTime? date) {
    if (date == null) return '—';
    return _shortDateFormatter.format(date);
  }

  /// Format: 25 tháng 06, 2026
  static String formatFull(DateTime? date) {
    if (date == null) return '—';
    return _dayMonthYearFormatter.format(date);
  }

  /// Parse ISO string to DateTime
  static DateTime? tryParse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Relative time: "2 giờ trước", "Hôm nay", "Hôm qua"
  static String relative(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return format(date);
  }
}
