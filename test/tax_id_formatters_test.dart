import 'package:daalsetu/utils/tax_id_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaxIdInputFormatter', () {
    test('uppercases and keeps the fixed PAN format', () {
      const formatter = TaxIdInputFormatter.pan();
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'abcde1234f9'),
      );

      expect(value.text, 'ABCDE1234F');
      expect(TaxIdValidator.pan(value.text), isNull);
      expect(TaxIdValidator.pan('ABCDE123F4'), isNotNull);
    });

    test('uppercases and keeps the fixed GST format', () {
      const formatter = TaxIdInputFormatter.gst();
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '27abcde1234f1z5'),
      );

      expect(value.text, '27ABCDE1234F1Z5');
      expect(TaxIdValidator.gst(value.text), isNull);
      expect(TaxIdValidator.gst('27ABCDE1234FAZ5'), isNotNull);
      expect(TaxIdValidator.gstMatchesPan('ABCDE1234F', value.text), isNull);
      expect(
        TaxIdValidator.gstMatchesPan('ABCDE1234X', value.text),
        isNotNull,
      );
    });
  });
}
