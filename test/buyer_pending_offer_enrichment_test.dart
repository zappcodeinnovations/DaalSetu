import 'package:daalsetu/services/buyer_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending offer summary is enriched with product inventory', () {
    final result = BuyerServices.mergePendingOfferProductDetail(
      {
        'id': 146,
        'title': 'toor angar',
        'offer_price': '1000.00',
        'status_code': 'active',
        'status_label': 'Active',
      },
      {
        'id': 146,
        'available_quantity': '20.100',
        'remaining_quantity': '20.100',
        'quantity_qtl': '20.100',
        'quantity_unit': 'qtl',
        'remaining_bag_count': 67,
        'packing_weight_kg': '30.000',
        'status_label': 'Available',
      },
    );

    expect(result['available_quantity'], '20.100');
    expect(result['quantity_qtl'], '20.100');
    expect(result['remaining_bag_count'], 67);
    expect(result['status_code'], 'active');
    expect(result['status_label'], 'Active');
  });
}
