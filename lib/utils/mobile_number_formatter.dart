import 'package:flutter/services.dart';

/// A mobile number is exactly 10 digits. A +91 / 91 / 0 that the phone's autofill or a paste puts in front
/// is dropped (not kept and not cut into a wrong 10-digit number); then at most 10 digits remain.
String cleanMobileNumber(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) digits = digits.substring(2);
  while (digits.length > 10 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits.length > 10 ? digits.substring(0, 10) : digits;
}

/// Same rule as the server: 10 digits, not starting with 0.
String? mobileNumberError(String? value) {
  final digits = (value ?? '').trim();
  if (!RegExp(r'^[1-9]\d{9}$').hasMatch(digits)) return 'Enter a valid 10-digit mobile number (without 0 or +91)';
  return null;
}

class MobileNumberFormatter extends TextInputFormatter {
  const MobileNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = cleanMobileNumber(newValue.text);
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(text: cleaned, selection: TextSelection.collapsed(offset: cleaned.length));
  }
}
