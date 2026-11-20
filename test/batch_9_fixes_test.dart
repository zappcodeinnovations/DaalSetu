import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/kyc_users/model/kyc_user_model.dart';
import 'package:intl/intl.dart';

void main() {
  group('Batch 9 Fixes Tests', () {
    test('KycUserModel parses dateJoined from kyc_submitted_at or submitted_at fallback', () {
      final json1 = {
        'id': 166,
        'name': 'rajesh kumar',
        'email': 'rajesh@gmail.com',
        'kyc_submitted_at': '2026-11-05T12:29:14Z',
      };
      final model1 = KycUserModel.fromJson(json1);
      expect(model1.dateJoined, '2026-11-05T12:29:14Z');

      final json2 = {
        'id': 167,
        'name': 'test user',
        'user': {'date_joined': '2026-11-06T10:00:00Z'},
      };
      final model2 = KycUserModel.fromJson(json2);
      expect(model2.dateJoined, '2026-11-06T10:00:00Z');
    });

    test('Recent activities cleaning regex removes double dots/ellipses before bullet and trailing', () {
      final input = 'arhar daal... • Buyer: Mariegold farm • Seller: Agrofarm';
      final cleanedDesc = input
          .replaceAll(RegExp(r'\.{2,}\s*•'), ' •')
          .replaceAll(RegExp(r'\.{2,}$'), '')
          .replaceAll('  ', ' ')
          .trim();
      expect(cleanedDesc, 'arhar daal • Buyer: Mariegold farm • Seller: Agrofarm');

      final input2 = 'mix daal...';
      final cleanedDesc2 = input2
          .replaceAll(RegExp(r'\.{2,}\s*•'), ' •')
          .replaceAll(RegExp(r'\.{2,}$'), '')
          .replaceAll('  ', ' ')
          .trim();
      expect(cleanedDesc2, 'mix daal');
    });

    test('Brokerage Bill date formatter converts YYYY-MM-DD to dd/MM/yyyy', () {
      String formatDate(dynamic dateStr) {
        if (dateStr == null) return '—';
        final str = dateStr.toString().trim();
        if (str.isEmpty || str == '—') return '—';
        try {
          final parsed = DateTime.tryParse(str);
          if (parsed != null) {
            return DateFormat('dd/MM/yyyy').format(parsed);
          }
        } catch (_) {}
        final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
        if (match != null) {
          return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
        }
        return str;
      }

      expect(formatDate('2026-11-05'), '05/11/2026');
      expect(formatDate('2026-11-06'), '06/11/2026');
      expect(formatDate('2026-11-07'), '07/11/2026');
      expect(formatDate(null), '—');
    });
  });
}
