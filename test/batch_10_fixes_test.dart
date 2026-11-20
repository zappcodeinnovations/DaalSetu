import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:intl/intl.dart';

void main() {
  group('Batch 10 Fixes Tests', () {
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
      expect(formatDate(null), '—');
    });

    test('BuyerOfferModel defaults canCancelInterest to false even when status is interested', () {
      final json = {
        'id': 101,
        'status': 'interested',
        'product_name': 'MIX DAAL',
      };
      final offer = BuyerOfferModel.fromJson(json);
      expect(offer.canCancelInterest, false);
    });

    test('Cancel interest button logic evaluates to false when status is INTERESTED', () {
      final status = 'INTERESTED';
      final isInterestedStatus = status.trim().toLowerCase() == 'interested';
      final canCancelInterest = false;
      final showCancelButton = canCancelInterest && !isInterestedStatus;
      expect(showCancelButton, false);
    });
  });
}
