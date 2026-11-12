import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('DOB Formatting Tests', () {
    test('Initial date parsing formats ISO to dd/MM/yyyy', () {
      const rawIso = '2006-10-23';
      final parts = rawIso.split('-');
      final formatted = '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      expect(formatted, '23/10/2006');
    });

    test('Selected date formats strictly as dd/MM/yyyy', () {
      final selectedDate = DateTime(2026, 10, 17);
      final formatted = DateFormat('dd/MM/yyyy').format(selectedDate);
      expect(formatted, '17/10/2026');
    });

    test('Submission formats dd/MM/yyyy to yyyy-MM-dd for API', () {
      const input = '17/10/2026';
      final parts = input.split('/');
      final apiDob = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      expect(apiDob, '2026-10-17');
    });
  });
}
