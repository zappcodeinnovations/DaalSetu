import 'package:daalsetu/modules/admin_dc/model/admin_challan_model.dart';
import 'package:daalsetu/modules/admin_dc/widgets/admin_challan_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _card(String status, VoidCallback? onDeliver) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AdminChallanCard(
            challan: AdminChallanModel(id: 7, status: status, items: const [], totalAmount: 0),
            onTap: () {},
            onMarkDelivered: onDeliver,
          ),
        ),
      ),
    );

void main() {
  testWidgets('a dispatched challan card has a full-width Mark as Delivered button', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_card('dispatched', () => taps++));
    final button = find.text('Mark as Delivered');
    expect(button, findsOneWidget);
    final size = tester.getSize(find.ancestor(of: button, matching: find.byType(ElevatedButton)).first);
    expect(size.height, 44);
    expect(size.width, greaterThan(250));
    await tester.tap(button);
    expect(taps, 1);
  });

  testWidgets('draft and delivered cards have no such button', (tester) async {
    for (final status in ['draft', 'delivered', 'cancelled']) {
      await tester.pumpWidget(_card(status, () {}));
      expect(find.text('Mark as Delivered'), findsNothing, reason: status);
    }
  });
}
