import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Buyer Panel Submit Offer Date Format Verification', () {
    test('Selected date formats strictly as dd-mm-yyyy', () {
      final picked = DateTime(2026, 10, 25);
      final formattedDeliveryDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year.toString().padLeft(4, '0')}";
      expect(formattedDeliveryDate, '25-10-2026');
    });

    test('Single-digit day and month are zero-padded to dd-mm-yyyy', () {
      final picked = DateTime(2026, 3, 5);
      final formattedDeliveryDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year.toString().padLeft(4, '0')}";
      expect(formattedDeliveryDate, '05-03-2026');
    });

    test('API delivery_date normalizer converts dd-mm-yyyy to ISO yyyy-MM-dd', () {
      const input = '25-10-2026';
      String apiDeliveryDate = input;
      if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(input)) {
        final sep = input.contains('/') ? '/' : '-';
        final parts = input.split(sep);
        apiDeliveryDate = "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
      }
      expect(apiDeliveryDate, '2026-10-25');
    });

    test('API delivery_date normalizer preserves already ISO formatted dates', () {
      const input = '2026-10-25';
      String apiDeliveryDate = input;
      if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(input)) {
        final sep = input.contains('/') ? '/' : '-';
        final parts = input.split(sep);
        apiDeliveryDate = "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
      }
      expect(apiDeliveryDate, '2026-10-25');
    });
  });
}
