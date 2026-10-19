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
}
