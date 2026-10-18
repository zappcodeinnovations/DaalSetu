import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/modules/transporter/offers/view/transporter_offers_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Offers & Requirements Page Tab Verification', () {
    testWidgets('BuyerOffersView shows "Offers" tab instead of "All"', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: BuyerOffersView(),
          ),
        ),
      );

      // Verify the screen title
      expect(find.text("Offers & Requirements"), findsOneWidget);

      // Verify the tab names
      expect(find.widgetWithText(Tab, "Offers"), findsOneWidget);
      expect(find.widgetWithText(Tab, "Today"), findsOneWidget);
      expect(find.widgetWithText(Tab, "Pending"), findsOneWidget);
      expect(find.widgetWithText(Tab, "Previous"), findsOneWidget);

      // Verify that "All" tab does not exist
      expect(find.widgetWithText(Tab, "All"), findsNothing);
    });

    testWidgets('TransporterOffersView shows "Offers" tab instead of "All Offers"', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: TransporterOffersView(),
          ),
        ),
      );

      // Verify the tab names
      expect(find.widgetWithText(Tab, "Offers"), findsOneWidget);
      expect(find.widgetWithText(Tab, "Today"), findsOneWidget);
      expect(find.widgetWithText(Tab, "Pending"), findsOneWidget);
      expect(find.widgetWithText(Tab, "Previous"), findsOneWidget);

      // Verify that "All Offers" tab does not exist
      expect(find.widgetWithText(Tab, "All Offers"), findsNothing);
    });
  });
}
