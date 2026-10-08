import 'package:flutter/services.dart';

/// Keeps PAN/GST values in the exact structure accepted by the web and API.
/// Values are uppercase, have no separators, and reject a character at an
/// invalid position while the user types.
class TaxIdInputFormatter extends TextInputFormatter {
  const TaxIdInputFormatter._(this._pattern);

  const TaxIdInputFormatter.pan() : _pattern = 'LLLLLDDDDL';
  const TaxIdInputFormatter.gst() : _pattern = 'DDLLLLLDDDDLDZA';

  final String _pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final source = newValue.text.toUpperCase();
    final output = StringBuffer();
    var position = 0;

    for (final codeUnit in source.codeUnits) {
      if (position >= _pattern.length) break;
      final character = String.fromCharCode(codeUnit);
      if (!_isAlphaNumeric(codeUnit)) continue;
      if (_matches(_pattern[position], codeUnit)) {
        output.write(character);
        position++;
      }
    }

    final value = output.toString();
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  static bool _isAlphaNumeric(int codeUnit) =>
      (codeUnit >= 48 && codeUnit <= 57) || (codeUnit >= 65 && codeUnit <= 90);

  static bool _matches(String expected, int codeUnit) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isLetter = codeUnit >= 65 && codeUnit <= 90;
    switch (expected) {
      case 'D':
        return isDigit;
      case 'L':
        return isLetter;
      case 'Z':
        return codeUnit == 90;
      case 'A':
        return isDigit || isLetter;
      default:
        return false;
    }
  }
}

class TaxIdValidator {
  TaxIdValidator._();

  static final RegExp _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final RegExp _gst = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9]Z[0-9A-Z]$',
  );

  static String? pan(String? value, {bool required = false}) {
    final cleaned = (value ?? '').trim().toUpperCase();
    if (cleaned.isEmpty) return required ? 'PAN number is required' : null;
    return _pan.hasMatch(cleaned) ? null : 'Use PAN format ABCDE1234F';
  }

  static String? gst(String? value, {bool required = false}) {
    final cleaned = (value ?? '').trim().toUpperCase();
    if (cleaned.isEmpty) return required ? 'GST number is required' : null;
    return _gst.hasMatch(cleaned) ? null : 'Use GST format 27ABCDE1234F1Z5';
  }

  /// The GST's middle 10 characters are the registered PAN.
  static String? gstMatchesPan(String? panValue, String? gstValue) {
    final pan = (panValue ?? '').trim().toUpperCase();
    final gst = (gstValue ?? '').trim().toUpperCase();
    if (pan.isEmpty || gst.isEmpty || gst.length != 15) return null;
    return gst.substring(2, 12) == pan
        ? null
        : 'GST PAN segment must match the PAN number';
  }
}
