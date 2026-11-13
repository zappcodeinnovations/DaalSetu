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

  test('prioritizes buyer full name and company name over buyer_unique_id', () {
    final interest = OfferInterestModel.fromJson({
      'id': 101,
      'buyer_name': 'Rajesh Sharma',
      'buyer_company': 'Sharma Agro Traders',
      'buyer_unique_id': 'BUY-9999-ID',
      'offered_amount': '65.00',
    });

    expect(interest.buyerName, 'Rajesh Sharma');
    expect(interest.buyerCompany, 'Sharma Agro Traders');
    // MoM 24: cards show the company, not the person.
    expect(interest.displayBuyerInfo, 'Sharma Agro Traders');
  });

  test('handles nested buyer map with first and last name', () {
    final interest = OfferInterestModel.fromJson({
      'id': 102,
      'buyer': {
        'first_name': 'Amit',
        'last_name': 'Patel',
        'company_name': 'Patel Pulses Ltd',
        'username': '9876543210',
      },
      'buyer_unique_id': 'BUY-1234-ID',
    });

    expect(interest.buyerName, 'Amit Patel');
    expect(interest.buyerCompany, 'Patel Pulses Ltd');
    // MoM 24: cards show the company, not the person.
    expect(interest.displayBuyerInfo, 'Patel Pulses Ltd');
  });
}
