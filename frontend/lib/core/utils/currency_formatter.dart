import 'package:intl/intl.dart';

/// Currency formatter for Vietnamese Dong (VND)
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _vndFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Format as full VND: 1.500.000 ₫
  static String format(num? amount) {
    if (amount == null) return '—';
    return _vndFormatter.format(amount);
  }

  /// Format as compact: 1,5M ₫
  static String compact(num? amount) {
    if (amount == null) return '—';
    return _compactFormatter.format(amount);
  }

  /// Format as plain number with thousand separators: 1.500.000
  static String number(num? amount) {
    if (amount == null) return '—';
    return NumberFormat('#,###', 'vi_VN').format(amount);
  }
}
