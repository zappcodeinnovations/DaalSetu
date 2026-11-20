import 'package:flutter/services.dart';

class InputValidators {
  InputValidators._();

  /// Indian vehicle registration (and RC) number: MH 12 AB 1234 -> state (2 letters), district (1-2 digits),
  /// series (1-3 letters), number (4 digits). Spaces are ignored; "BH" series plates (22BH1234AB) also pass.
  static final RegExp _vehicleNumberPattern = RegExp(
    r'^(?:[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}|[0-9]{2}BH[0-9]{4}[A-Z]{1,2})$',
  );

  /// Upper-case without spaces or dashes: "mh 12-ab 1234" -> "MH12AB1234".
  static String compactVehicleNumber(String? value) =>
      (value ?? '').toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static String? vehicleNumber(String? value, {String label = 'Vehicle number', bool required = false}) {
    final number = compactVehicleNumber(value);
    if (number.isEmpty) return required ? '$label is required' : null;
    if (!_vehicleNumberPattern.hasMatch(number)) {
      return 'Enter a valid ${label.toLowerCase()}, like MH12AB1234';
    }
    return null;
  }

  /// Indian driving licence number: 2 letters + 13 digits (15 characters), e.g. MH1220110062821.
  static final RegExp _licenseNumberPattern = RegExp(r'^[A-Z]{2}[0-9]{13}$');

  static String compactLicenseNumber(String? value) =>
      (value ?? '').toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static String? licenseNumber(String? value, {bool required = false}) {
    final number = compactLicenseNumber(value);
    if (number.isEmpty) return required ? 'License number is required' : null;
    if (!_licenseNumberPattern.hasMatch(number)) {
      return 'License number must be 2 letters followed by 13 digits (15 characters)';
    }
    return null;
  }

  static final RegExp _emailPattern = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9-]+(?:\.[A-Z0-9-]+)*\.[A-Z]{2,63}$',
    caseSensitive: false,
  );

  static String? email(String? value, {bool required = false}) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return required ? 'Email is required' : null;
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    final domain = email.substring(email.lastIndexOf('@') + 1);
    if (domain
        .split('.')
        .any(
          (label) =>
              label.isEmpty || label.startsWith('-') || label.endsWith('-'),
        )) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static final RegExp _namePattern = RegExp(r"^[\p{L}\p{M}\p{N} .'-]+$", unicode: true);
  static final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);

  /// Same rule as the backend: letters and numbers are fine, but a name made
  /// only of numbers/symbols is rejected.
  static String? personName(String? value, {String label = 'Name'}) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return null;
    if (!_namePattern.hasMatch(name)) {
      return "$label can contain only letters, numbers, spaces, dots, apostrophes and hyphens";
    }
    if (!_letterPattern.hasMatch(name)) {
      return '$label must contain letters; it cannot be only numbers';
    }
    return null;
  }
}

/// Lets only valid beginnings of an Indian ID through while typing, so a wrong character never gets in.
///
/// * [vehicle]: MH12AB1234 - 2 letters, 1-2 digits, 1-3 letters, 4 digits (or a BH series plate, 22BH1234AB).
/// * [license]: MH1220110062821 - 2 letters, then 13 digits.
///
/// Letters become capitals; spaces and dashes are dropped (they are optional when typing).
class IndianIdInputFormatter extends TextInputFormatter {
  IndianIdInputFormatter._(this._pattern);

  IndianIdInputFormatter.vehicle() : this._(_vehiclePrefix);
  IndianIdInputFormatter.license() : this._(_licensePrefix);

  final RegExp _pattern;

  // Every prefix of a valid number must match; anything else is rejected as it is typed.
  static final RegExp _vehiclePrefix = RegExp(
    r'^(?:[A-Z]{0,2}|[A-Z]{2}[0-9]{1,2}|[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{0,4}'
    r'|[0-9]{1,2}|[0-9]{2}B|[0-9]{2}BH[0-9]{0,4}[A-Z]{0,2})$',
  );
  static final RegExp _licensePrefix = RegExp(r'^(?:[A-Z]{0,2}|[A-Z]{2}[0-9]{0,13})$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (!_pattern.hasMatch(cleaned)) return oldValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
