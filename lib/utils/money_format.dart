import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// Rupee amount with Indian grouping: "43637.967" -> "₹43,637.97", "4950.00000" -> "₹4,950.00".
/// Empty values read "-" and anything unparsable is shown as-is.
String formatInr(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return '-';
  final parsed = num.tryParse(value.toString().replaceAll(',', '').trim());
  return parsed == null ? value.toString() : _inr.format(parsed);
}

/// Short chart-axis label: 850 -> "850", 2500 -> "2.5k", 45000 -> "45k", 250000 -> "2.5L".
String compactInr(num value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(value < 10000 ? 1 : 0)}k';
  return value.toStringAsFixed(0);
}
