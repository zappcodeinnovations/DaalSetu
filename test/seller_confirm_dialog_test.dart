import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/common/seller_ui.dart';
import 'package:get/get.dart';

void main() {
  kycReapprovalDialogTests();
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

void kycReapprovalDialogTests() {
  testWidgets('KYC Re-approval dialog: "Send Request" stays on one line and both buttons are the same size', (tester) async {
    tester.view.physicalSize = const Size(459, 1024); // the phone of the bug report
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SellerUi.confirm(
                'KYC Re-approval',
                'Send your KYC to the admin for review again?',
                confirmText: 'Send Request',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    final send = find.widgetWithText(ElevatedButton, 'Send Request');
    final cancel = find.widgetWithText(OutlinedButton, 'Cancel');
    expect(tester.getSize(send), tester.getSize(cancel));
    // One line of text: the button is no taller than a single-line button (46 minimum + no wrapped second line).
    expect(tester.getSize(send).height, lessThanOrEqualTo(48));
    expect(tester.getSize(find.text('Send Request')).height, lessThan(24));
  });
}
