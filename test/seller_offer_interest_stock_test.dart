import 'package:daalsetu/modules/seller/products/controller/seller_negotiation_controller.dart';
import 'package:daalsetu/modules/seller/products/model/offer_interest_model.dart';
import 'package:daalsetu/modules/seller/products/view/seller_offer_interests_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Serves fixed rows; no polling or network in the widget test.
class _FixedInterests extends SellerNegotiationController {
  _FixedInterests(List<OfferInterestModel> rows) : super(productId: 0) {
    interestsList.assignAll(rows);
    isLoading.value = false;
  }

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> fetchInterests({bool silent = false}) async {}
}

void main() {
  test('an open offer whose stock is reserved elsewhere can only be rejected', () {
    final blocked = OfferInterestModel.fromJson({
      'id': 7, 'status': 'interested',
      'can_seller_action': false, 'can_seller_reject': true,
      'stock_blocked': true,
      'blocked_reason': 'Stock reserved for another accepted offer: 0 qtl free, 50.1 qtl needed.',
    });
    expect(blocked.canSellerAction, isFalse);
    expect(blocked.canSellerReject, isTrue);
    expect(blocked.stockBlocked, isTrue);
    expect(blocked.blockedReason, contains('reserved for another accepted offer'));
  });

  test('older servers without the new keys keep the previous behaviour', () {
    final open = OfferInterestModel.fromJson({'id': 8, 'status': 'interested'});
    expect(open.stockBlocked, isFalse);
    expect(open.canSellerAction, isTrue);
    expect(open.canSellerReject, isTrue);
  });

  testWidgets('seller card: reserved stock shows the reason and only Reject', (tester) async {
    Get.testMode = true;
    Get.put<SellerNegotiationController>(
      _FixedInterests([
        OfferInterestModel.fromJson({
          'id': 1, 'transaction_id': 'INT-1', 'buyer_unique_id': 'BUY-A', 'status': 'buyer_confirmed',
          'offered_amount': '77.00', 'required_quantity': '50.100', 'can_open_negotiation': true,
        }),
        OfferInterestModel.fromJson({
          'id': 2, 'transaction_id': 'INT-2', 'buyer_unique_id': 'BUY-A', 'status': 'interested',
          'offered_amount': '57.00', 'required_quantity': '50.100', 'can_seller_action': false,
          'can_seller_reject': true, 'can_open_negotiation': true, 'stock_blocked': true,
          'blocked_reason': 'Stock reserved for another accepted offer: 0 qtl free, 50.1 qtl needed.',
        }),
      ]),
      tag: 'seller_negotiation_0',
    );
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: SellerOfferInterestsView()));
    await tester.pump();

    expect(find.textContaining('Stock reserved for another accepted offer'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
    expect(find.text('ACCEPT'), findsNothing);
    expect(find.text('NEGOTIATE PRICE / QUANTITY'), findsNothing);
    Get.reset();
  });
}
