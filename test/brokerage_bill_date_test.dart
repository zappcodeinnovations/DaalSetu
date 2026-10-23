import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Create Brokerage Bill Date Formatting & Resilience', () {
    String formatDateDisplay(DateTime? value) {
      if (value == null) return '';
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }

    String dateValue(DateTime value) =>
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

    DateTime? tryParseAnyDate(String? text) {
      if (text == null || text.trim().isEmpty) return null;
      final trimmed = text.trim();
      final iso = DateTime.tryParse(trimmed);
      if (iso != null) return iso;
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      return null;
    }

    test('formats DateTime into regional DD/MM/YYYY for UI display', () {
      final dt = DateTime(2026, 10, 23);
      expect(formatDateDisplay(dt), '23/10/2026');
      expect(formatDateDisplay(null), '');
    });

    test('formats DateTime into ISO YYYY-MM-DD for backend API payload', () {
      final dt = DateTime(2026, 10, 23);
      expect(dateValue(dt), '2026-10-23');
    });

    test('parses both DD/MM/YYYY and ISO formats correctly for roundtrip compatibility', () {
      final parsedRegional = tryParseAnyDate('23/10/2026');
      expect(parsedRegional, isNotNull);
      expect(parsedRegional!.year, 2026);
      expect(parsedRegional.month, 10);
      expect(parsedRegional.day, 23);
      expect(dateValue(parsedRegional), '2026-10-23');

      final parsedIso = tryParseAnyDate('2026-10-23');
      expect(parsedIso, isNotNull);
      expect(parsedIso!.year, 2026);
      expect(parsedIso.month, 10);
      expect(parsedIso.day, 23);
      expect(formatDateDisplay(parsedIso), '23/10/2026');

      expect(tryParseAnyDate(''), isNull);
      expect(tryParseAnyDate(null), isNull);
    });
  });
}
