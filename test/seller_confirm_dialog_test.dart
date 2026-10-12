import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/common/seller_ui.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('SellerUi.confirm places primary confirm button first and cancel button second',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SellerUi.confirm(
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

    final dialog = tester.widget<AlertDialog>(dialogFinder);
    expect(dialog.actions, isNotNull);
    expect(dialog.actions!.length, equals(2));

    // Confirm that the first action is the primary "Accept" button
    final firstAction = dialog.actions![0];
    expect(firstAction, isA<ElevatedButton>());
    expect(find.descendant(of: find.byWidget(firstAction), matching: find.text('Accept')),
        findsOneWidget);

    // Confirm that the second action is the "Cancel" button
    final secondAction = dialog.actions![1];
    expect(secondAction, isA<TextButton>());
    expect(find.descendant(of: find.byWidget(secondAction), matching: find.text('Cancel')),
        findsOneWidget);

    // Verify visual order on screen (Accept on left, Cancel on right)
    final acceptPos = tester.getTopLeft(find.text('Accept'));
    final cancelPos = tester.getTopLeft(find.text('Cancel'));
    expect(acceptPos.dx, lessThan(cancelPos.dx));
  });
}
