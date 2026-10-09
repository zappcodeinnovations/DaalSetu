import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';

void main() {
  group('offer interest flow permissions', () {
    test('buyer initial interest exposes only edit and cancel', () {
      final offer = BuyerOfferModel.fromJson({
        'interest_id': 11,
        'product_id': 7,
        'status': 'interested',
        'can_edit': true,
        'can_cancel': true,
        'can_open_negotiation': false,
        'can_buyer_accept': false,
        'can_buyer_reject': false,
      });

      expect(offer.canEditInterest, isTrue);
      expect(offer.canCancelInterest, isTrue);
      expect(offer.canOpenNegotiation, isFalse);
      expect(offer.canBuyerAccept, isFalse);
      expect(offer.canBuyerReject, isFalse);
    });

    test('buyer gets negotiation and decision after seller proposal', () {
      final offer = BuyerOfferModel.fromJson({
        'interest_id': 12,
        'product_id': 8,
        'status': 'interested',
        'can_edit': false,
        'can_cancel': false,
        'can_open_negotiation': true,
        'can_buyer_accept': true,
        'can_buyer_reject': true,
        'has_seller_proposal': true,
      });

      expect(offer.canEditInterest, isFalse);
      expect(offer.canCancelInterest, isFalse);
      expect(offer.canOpenNegotiation, isTrue);
      expect(offer.canBuyerAccept, isTrue);
      expect(offer.canBuyerReject, isTrue);
    });

    test('seller and admin action flags parse from API response', () {
      final interest = OfferInterestModel.fromJson({
        'id': 13,
        'status': 'buyer_confirmed',
        'can_seller_action': false,
        'can_open_negotiation': true,
        'can_admin_final_action': true,
        'is_read_only': true,
      });

      expect(interest.canSellerAction, isFalse);
      expect(interest.canOpenNegotiation, isTrue);
      expect(interest.canAdminFinalAction, isTrue);
      expect(interest.isReadOnly, isTrue);
    });
  });
}
