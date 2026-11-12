import 'package:daalsetu/utils/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sub Admin email validation', () {
    test('rejects incomplete and malformed email addresses', () {
      expect(
        InputValidators.email('rest@gmail.c', required: true),
        'Enter a valid email address',
      );
      expect(
        InputValidators.email('rest@-gmail.com', required: true),
        'Enter a valid email address',
      );
      expect(
        InputValidators.email('rest@gmail', required: true),
        'Enter a valid email address',
      );
    });

    test('accepts a complete email and validates required input', () {
      expect(InputValidators.email('rest@gmail.com', required: true), isNull);
      expect(InputValidators.email('', required: true), 'Email is required');
      expect(InputValidators.email('', required: false), isNull);
    });
  });
}
