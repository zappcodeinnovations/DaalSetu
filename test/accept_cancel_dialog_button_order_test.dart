import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/admin_catalog/view/approve_deal_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Transport bids confirmation dialog has Accept button first and Cancel button second',
      (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Accept transport bid?'),
                    content: const Text(
                      'All other pending bids for this contract will be rejected.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Transport Bid Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Transport Bid Dialog'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);

    final dialog = tester.widget<AlertDialog>(dialogFinder);
    expect(dialog.actions, isNotNull);
    expect(dialog.actions!.length, equals(2));

    // First action should be Accept
    final firstAction = dialog.actions![0];
    expect(find.descendant(of: find.byWidget(firstAction), matching: find.text('Accept')), findsOneWidget);

    // Second action should be Cancel
    final secondAction = dialog.actions![1];
    expect(find.descendant(of: find.byWidget(secondAction), matching: find.text('Cancel')), findsOneWidget);

    // Visual position: Accept (left) < Cancel (right)
    final acceptPos = tester.getTopLeft(find.text('Accept'));
    final cancelPos = tester.getTopLeft(find.text('Cancel'));
    expect(acceptPos.dx, lessThan(cancelPos.dx));

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('Negotiation chat confirmation dialog has Accept button first and Cancel button second',
      (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmed = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Accept buyer interest?'),
                    content: const Text(
                      'This will move the negotiation to the next confirmation step.',
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Get.back(result: true),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Negotiation Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Negotiation Dialog'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);

    final dialog = tester.widget<AlertDialog>(dialogFinder);
    expect(dialog.actions, isNotNull);
    expect(dialog.actions!.length, equals(2));

    // First action should be Accept
    final firstAction = dialog.actions![0];
    expect(find.descendant(of: find.byWidget(firstAction), matching: find.text('Accept')), findsOneWidget);

    // Second action should be Cancel
    final secondAction = dialog.actions![1];
    expect(find.descendant(of: find.byWidget(secondAction), matching: find.text('Cancel')), findsOneWidget);

    // Visual position: Accept (left) < Cancel (right)
    final acceptPos = tester.getTopLeft(find.text('Accept'));
    final cancelPos = tester.getTopLeft(find.text('Cancel'));
    expect(acceptPos.dx, lessThan(cancelPos.dx));

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('ApproveDealDialog renders Accept Interest first and Cancel second',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: ApproveDealDialog(
            buyerName: 'Test Buyer',
            offerTitle: 'Test Offer',
          ),
        ),
      ),
    );

    await tester.pump();

    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);

    final dialog = tester.widget<AlertDialog>(dialogFinder);
    expect(dialog.actions, isNotNull);
    expect(dialog.actions!.length, equals(2));

    // First action is FilledButton with "Accept Interest"
    final firstAction = dialog.actions![0];
    expect(find.descendant(of: find.byWidget(firstAction), matching: find.text('Accept Interest')), findsOneWidget);

    // Second action is TextButton with "Cancel"
    final secondAction = dialog.actions![1];
    expect(find.descendant(of: find.byWidget(secondAction), matching: find.text('Cancel')), findsOneWidget);

    final acceptPos = tester.getTopLeft(find.text('Accept Interest'));
    final cancelPos = tester.getTopLeft(find.text('Cancel'));
    expect(acceptPos.dx, lessThan(cancelPos.dx));
  });
}
