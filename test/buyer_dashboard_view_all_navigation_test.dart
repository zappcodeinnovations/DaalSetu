import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_activity_view.dart';

void main() {
  testWidgets('BuyerActivityView with initialIndex: 0 opens My Interests tab', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerActivityView(initialIndex: 0),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    final tabController = DefaultTabController.of(tester.element(find.byType(TabBar)));
    expect(tabController.index, 0);

    expect(find.text('My Interests'), findsOneWidget);
    expect(find.text('My Requirements'), findsOneWidget);
  });
}
