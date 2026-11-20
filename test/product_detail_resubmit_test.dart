import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductDetailScreen takes the same "already submitted" answer as the offer card', () {
    var submitted = false;
    final screen = ProductDetailScreen(productId: 1, onSubmitOffer: (_) {}, isOfferSubmitted: () => submitted);
    expect(screen.isOfferSubmitted!(), isFalse);
    submitted = true;
    expect(screen.isOfferSubmitted!(), isTrue);
  });
}
