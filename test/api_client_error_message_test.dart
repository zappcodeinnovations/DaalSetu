import 'package:daalsetu/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient.userFriendlyErrorMessage', () {
    test('formats an invalid branch reference code', () {
      expect(
        ApiClient.userFriendlyErrorMessage(
          'Exception: Invalid branch ref code.',
        ),
        'Invalid branch reference code. Please check the code and try again.',
      );
    });

    test('formats backend branch-code field errors', () {
      expect(
        ApiClient.userFriendlyErrorMessage(
          'Branch reference code: This branch code does not exist.',
        ),
        'Invalid branch reference code. Please check the code and try again.',
      );
    });

    test('hides technical transporter field names', () {
      expect(
        ApiClient.userFriendlyErrorMessage(
          'transporter_id: This field is required.',
        ),
        'Select a transporter before continuing.',
      );
    });
  });
}
