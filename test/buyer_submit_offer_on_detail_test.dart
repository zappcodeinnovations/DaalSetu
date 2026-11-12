import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// MoM 7: the buyer gets "Submit Offer" on the seller's offer page.
void main() {
  BuyerOfferModel offer(Map<String, dynamic> extra) => BuyerOfferModel.fromJson({
        'id': 7,
        'product_id': 7,
        'title': 'Toor Dal',
        'status': 'available',
        'is_active': true,
        'available_quantity': '50',
        ...extra,
      });

  test('an open offer gets the Submit Offer callback', () {
    final open = offer({});
    expect(open.canSubmitOffer, isTrue);
    expect(buyerSubmitOfferCallback(open), isNotNull);
  });

  test('expired or out-of-stock offers get no Submit Offer button', () {
    expect(buyerSubmitOfferCallback(offer({'is_expired': true})), isNull);
    expect(buyerSubmitOfferCallback(offer({'status': 'out_of_stock', 'available_quantity': '0'})), isNull);
  });

  test('the offer page accepts the callback; seller/admin pages pass none', () {
    void handler(BuildContext context) {}
    expect(const ProductDetailScreen(productId: 7).onSubmitOffer, isNull);
    expect(ProductDetailScreen(productId: 7, onSubmitOffer: handler).onSubmitOffer, isNotNull);
  });
}
