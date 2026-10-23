import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/transporter/bidding/model/transporter_bid_model.dart';
import 'package:daalsetu/modules/transporter/bidding/view/transporter_bidding_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  final testOffer = ShipmentOfferModel(
    id: 101,
    contractId: 'JBC2610217195',
    productTitle: 'Yellow Peas',
    pickupLocation: 'Nagpur Warehouse',
    deliveryLocation: 'Bhopal Warehouse',
    loadingDateRange: '2026-10-22 to 2026-10-25',
    dealQuantity: '50',
    quantityUnit: 'MT',
    currentLowestBid: '4800',
    activeBidCount: 2,
  );

  testWidgets('Place Bid modal uses primary orange/yellow theme and no teal accents', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TransporterBiddingView.showBidDialog(context, testOffer),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // 1. Verify dialog rendered
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Place Bid'), findsOneWidget);
    expect(find.text('Contract ID: JBC2610217195'), findsOneWidget);
    expect(find.text('Bid Amount'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);

    // 2. Verify Header bar styling uses primary orange/yellow gradient
    final containers = tester.widgetList<Container>(find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Container),
    ));

    final headerContainer = containers.firstWhere(
      (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).gradient is LinearGradient,
    );
    final headerGradient = (headerContainer.decoration as BoxDecoration).gradient as LinearGradient;
    expect(headerGradient.colors, contains(const Color(0xFFFFB300)));
    expect(headerGradient.colors, contains(const Color(0xFFF57C00)));

    // 3. Verify Submit button uses the primary orange/yellow gold color (not legacy teal 0xFF0F766E)
    final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Submit');
    expect(submitButtonFinder, findsOneWidget);
    final submitButton = tester.widget<ElevatedButton>(submitButtonFinder);
    expect(
      submitButton.style?.backgroundColor?.resolve({}),
      equals(const Color(0xFFFFB300)),
    );

    // 4. Verify TextField focusedBorder uses primary brand gold
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.cursorColor, equals(const Color(0xFFFFB300)));
    final border = textField.decoration?.focusedBorder as OutlineInputBorder?;
    expect(border, isNotNull);
    expect(border!.borderSide.color, equals(const Color(0xFFFFB300)));

    // 5. Ensure legacy teal (0xFF0F766E) and dark navy (0xFF131D2E) do not exist
    expect(find.byWidgetPredicate((widget) {
      if (widget is Container) {
        if (widget.color == const Color(0xFF131D2E) || widget.color == const Color(0xFF0F766E)) {
          return true;
        }
      }
      return false;
    }), findsNothing);
  });
}
