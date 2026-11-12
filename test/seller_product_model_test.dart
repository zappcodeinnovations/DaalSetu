import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the seller offer API fields used by product cards', () {
    final product = SellerProductModel.fromJson({
      'id': 42,
      'title': 'Premium Toor Dal',
      'category_id': 6,
      'category_name': 'Toor Dal',
      'brand': {'id': 3, 'name': 'DaalSetu Select'},
      'amount': '6500.00',
      'amount_unit': 'qtl',
      'status': 'active',
      'is_active': true,
      'is_expired': false,
      'remaining_bag_count': 20,
      'packing_weight_kg': '30.000',
      'loading_location': 'Pune Warehouse',
      'interested_count': 4,
      'created_at': '2026-10-09T10:00:00Z',
    });

    expect(product.categoryName, 'Toor Dal');
    expect(product.brandName, 'DaalSetu Select');
    expect(product.unit, 'qtl');
    expect(product.bagCount, 20);
    expect(product.interestCount, 4);
    expect(product.loadingLocation, 'Pune Warehouse');
  });

  test('does not render a backend date range as a loading location', () {
    final product = SellerProductModel.fromJson({
      'id': 43,
      'loading_location': '2026-10-16 -> 2026-10-16',
    });

    expect(product.loadingLocation, isEmpty);
  });
}
