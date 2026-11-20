import 'package:daalsetu/modules/transporter/bidding/controller/transporter_bidding_controller.dart';
import 'package:daalsetu/modules/transporter/bidding/view/transporter_bidding_view.dart';
import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeBidding extends TransporterBiddingController {
  int silentOffers = 0;
  int silentBids = 0;

  @override
  Future<void> fetchOffers({bool silent = false}) async {
    if (silent) silentOffers++;
  }

  @override
  Future<void> fetchMyBids({bool silent = false}) async {
    if (silent) silentBids++;
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets('Shipments: the visible tab refreshes itself (Active Shipment Offers, then My Deals)', (tester) async {
    final controller = Get.put<TransporterBiddingController>(_FakeBidding()) as _FakeBidding;
    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [pageRefreshRouteObserver],
        home: const TransporterBiddingView(),
      ),
    );
    await tester.pump();

    // Offers tab is on screen: only it polls.
    await tester.pump(const Duration(seconds: 11));
    expect(controller.silentOffers, greaterThanOrEqualTo(1));
    expect(controller.silentBids, 0);

    // Switch to My Deals: that tab polls now.
    await tester.tap(find.text('My Deals'));
    await tester.pumpAndSettle();
    final offersBefore = controller.silentOffers;
    await tester.pump(const Duration(seconds: 11));
    expect(controller.silentBids, greaterThanOrEqualTo(1));
    expect(controller.silentOffers, offersBefore);
  });
}
