import 'package:daalsetu/modules/seller/products/model/offer_interest_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two offers from the same buyer keep their own transaction ids', () {
    // Same buyer, one offer already confirmed and a newer one still open (the reported "duplicate").
    final confirmed = OfferInterestModel.fromJson({
      'id': 41, 'transaction_id': 'INT-20261010-1111', 'buyer_unique_id': 'BUY-20261010-SKGT',
      'offered_amount': '77.00', 'status': 'buyer_confirmed', 'created_at': 'Oct 10, 2026 10:00 AM',
    });
    final open = OfferInterestModel.fromJson({
      'id': 42, 'transaction_id': 'INT-20261010-2222', 'buyer_unique_id': 'BUY-20261010-SKGT',
      'offered_amount': '57.00', 'status': 'interested', 'created_at': 'Oct 10, 2026 11:30 AM',
    });

    expect(confirmed.buyerName, open.buyerName);
    expect(confirmed.transactionId, 'INT-20261010-1111');
    expect(open.transactionId, 'INT-20261010-2222');
    expect(open.createdAt, 'Oct 10, 2026 11:30 AM');
  });
}
