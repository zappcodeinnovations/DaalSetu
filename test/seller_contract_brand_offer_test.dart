import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/contracts/model/seller_contract_model.dart';

void main() {
  group('SellerContractModel brand and offer name parsing (TSK-035)', () {
    test('parses product_title and product_brand_name from contract JSON payload', () {
      final json = {
        'id': 101,
        'contract_id': 'JBC2611074575',
        'product_title': 'mix daal',
        'product_brand_name': 'Natureland Organics',
        'product_category_name': 'Split Yellow',
        'deal_amount': '25.00',
        'deal_quantity': '50.000',
        'status': 'active',
        'buyer_company': 'Test company',
        'display_buyer_id': 'rajesh kumar (ID:166 | BUY9CED677AB6)',
        'confirmed_at': '2026-11-07 13:09:00',
      };

      final model = SellerContractModel.fromJson(json);

      expect(model.id, 101);
      expect(model.contractId, 'JBC2611074575');
      expect(model.productTitle, 'mix daal');
      expect(model.offerName, 'mix daal');
      expect(model.brandName, 'Natureland Organics');
      expect(model.categoryName, 'Split Yellow');
      expect(model.commodity, 'Split Yellow');
      expect(model.dealAmount, '25.00');
    });

    test('falls back gracefully when brand or offer name are missing', () {
      final json = {
        'id': 102,
        'contract_id': 'JBC2611074576',
        'status': 'active',
      };

      final model = SellerContractModel.fromJson(json);

      expect(model.productTitle, isNull);
      expect(model.brandName, isNull);
    });
  });
}

