class InputValidators {
  InputValidators._();

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
