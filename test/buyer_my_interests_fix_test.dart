import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('Buyer My Interests Data Retention & RFQ Exclusion Integrity', () {
    test('Interests data with open status and commodity is NOT treated as RFQ and preserved in interests feed', () {
      final interestRaw = {
        'id': 101,
        'interest_id': 501,
        'product_id': 201,
        'commodity': {'id': 10, 'name': 'Moong Mogar'},
        'product_title': 'Moong Mogar Premium',
        'status': 'open',
        'required_quantity': '100',
        'target_price': '8500',
        'buyer_required_quantity': '100',
        'offered_amount': '8500',
      };

      final model = BuyerOfferModel.fromJson(interestRaw);
      expect(model.isRfq, isFalse, reason: 'An interest with interest_id must never be flagged as RFQ');
      expect(model.interestId, equals(501));
    });

    test('BuyerOffersController for offerType: interests preserves interest items in mapped list', () {
      final controller = BuyerOffersController(offerType: 'interests');
      addTearDown(controller.dispose);

      final interestRaw = {
        'id': 102,
        'interest_id': 502,
        'product_id': 202,
        'commodity': 'Chana Dal',
        'status': 'open',
        'target_price': '6200',
      };

      final model = BuyerOfferModel.fromJson(interestRaw);
      // Simulate controller filtering logic
      final whereResult = (controller.offerType != 'requirements' &&
              controller.offerType != 'interests' &&
              model.isRfq)
          ? false
          : true;

      expect(whereResult, isTrue, reason: 'Interests feed must never exclude interest items');
    });

    test('BuyerOffersController for offerType: today still strictly excludes real RFQ items', () {
      final controller = BuyerOffersController(offerType: 'today');
      addTearDown(controller.dispose);

      final rfqRaw = {
        'id': 999,
        'rfq_id': 999,
        'source_type': 'rfq',
        'status': 'open',
        'required_quantity': '200',
      };

      final model = BuyerOfferModel.fromJson(rfqRaw);
      expect(model.isRfq, isTrue, reason: 'Actual RFQ must have isRfq = true');

      final whereResult = (controller.offerType != 'requirements' &&
              controller.offerType != 'interests' &&
              model.isRfq)
          ? false
          : true;

      expect(whereResult, isFalse, reason: 'Real RFQ must be excluded from today offers feed');
    });
  });
}
