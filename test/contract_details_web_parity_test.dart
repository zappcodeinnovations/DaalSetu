import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the contract details carry the web panel\'s trade value, what was offered / asked, dates, GST and address', () {
    final detail = ContractDetailModel.fromJson({
      'id': 84,
      'contract_id': 'JBC2610173027',
      'product_title': 'Toor Dal',
      'deal_amount': '500.00',
      'deal_quantity': '3.900',
      'amount_unit': 'qtl',
      'quantity_unit': 'qtl',
      'status': 'active',
      'trade_value': '1950.00',
      'seller_quantity': '5.000',
      'buyer_offer_amount': '480.00',
      'buyer_required_quantity': '3.900',
      'deal_date': '19/11/2026 10:15',
      'delivery_date': '25/11/2026',
      'loading_from_date': '2026-11-20',
      'loading_to_date': '2026-11-22',
      'buyer_gst': '27ABCDE1234F1Z5',
      'seller_address': 'Plot 12, Nagpur',
      'contract_edit_history': [
        {'timestamp': '19/11/2026', 'message': 'Rate changed'},
      ],
    });

    expect(detail.tradeValue, '1950.00');
    expect(detail.sellerQuantity, '5.000');
    expect(detail.buyerOfferAmount, '480.00');
    expect(detail.buyerRequiredQuantity, '3.900');
    expect(detail.dealDate, '19/11/2026 10:15');
    expect(detail.deliveryDate, '25/11/2026');
    expect(detail.loadingFromDate, '2026-11-20');
    expect(detail.buyerGst, '27ABCDE1234F1Z5');
    expect(detail.sellerAddress, 'Plot 12, Nagpur');
    expect(detail.sellerGst, isNull);
    expect(detail.editHistory.single['message'], 'Rate changed');
  });
}
