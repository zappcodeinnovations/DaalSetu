import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/common/seller_ui.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('SellerUi.confirm places primary confirm button first and cancel button second',
      (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await SellerUi.confirm(
                'Accept buyer interest?',
                'This will send the buyer interest for the next confirmation step.',
                confirmText: 'Accept',
                color: Colors.green,
                primaryFirst: true,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);

    // Both buttons are one row: Accept (ElevatedButton) first, Cancel (boxed OutlinedButton) second,
    // exactly the same size.
    final accept = find.widgetWithText(ElevatedButton, 'Accept');
    final cancel = find.widgetWithText(OutlinedButton, 'Cancel');
    expect(accept, findsOneWidget);
    expect(cancel, findsOneWidget);
    expect(tester.widget<OutlinedButton>(cancel).style!.side!.resolve({})!.width, greaterThan(0));
    expect(tester.getSize(accept), tester.getSize(cancel));

    // Verify visual order on screen (Accept on left, Cancel on right)
    final acceptPos = tester.getTopLeft(find.text('Accept'));
    final cancelPos = tester.getTopLeft(find.text('Cancel'));
    expect(acceptPos.dx, lessThan(cancelPos.dx));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
