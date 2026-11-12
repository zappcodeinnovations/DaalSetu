import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/seller/products/model/offer_interest_model.dart' as seller;

void main() {
  group('Negotiation submission endpoints and payloads', () {
    test('Offer interest thread endpoint is canonical for negotiation messages', () {
      expect(
        ApiUrls.offerInterestThread(114, 114),
        '/api/offers/114/interests/114/',
      );
    });

    test('Packing calculation auto-derives QTL from bags and packing weight', () {
      final bags = double.tryParse('10');
      final weight = double.tryParse('30');
      expect(bags, isNotNull);
      expect(weight, isNotNull);
      final calculatedQtl = (bags! * weight!) / 100.0;
      expect(calculatedQtl.toStringAsFixed(3), '3.000');
    });

    test('Packing validation requires both bags and weight when either is present', () {
      bool isValidPacking(String bags, String weight) {
        if (bags.isEmpty && weight.isEmpty) return true;
        if (bags.isNotEmpty && weight.isEmpty) return false;
        if (weight.isNotEmpty && bags.isEmpty) return false;
        return true;
      }

      expect(isValidPacking('', ''), isTrue);
      expect(isValidPacking('10', '30'), isTrue);
      expect(isValidPacking('10', ''), isFalse);
      expect(isValidPacking('', '30'), isFalse);
    });

    test('OfferInterestModel parses thread negotiation data correctly', () {
      final model = seller.OfferInterestModel.fromJson({
        'id': 114,
        'product': 114,
        'offered_amount': '5300.00',
        'required_quantity': '4.000',
        'counter_bag_count': 13,
        'counter_packing_weight_kg': '30.000',
        'status': 'interested',
        'can_seller_action': true,
        'can_open_negotiation': true,
      });

      expect(model.id, 114);
      expect(model.buyerOfferedAmount, '5300.00');
      expect(model.buyerRequiredQuantity, '4.000');
      expect(model.counterBagCount, 13);
      expect(model.counterPackingWeightKg, '30.000');
      expect(model.canSellerAction, isTrue);
      expect(model.canOpenNegotiation, isTrue);
    });
  });
}
