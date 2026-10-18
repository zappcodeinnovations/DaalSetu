import 'package:daalsetu/modules/admin_catalog/view/admin_module_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'dummy_token'});
  });

  testWidgets('Category Requests module renders Buyer Category Management header and All Buyers tab', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminModuleListScreen(
          moduleKey: 'category_requests',
        ),
      ),
    );

    // Initial build
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title matches web parity: "Buyer Category Management"
    expect(find.text('Buyer Category Management'), findsOneWidget);

    // Verify Segmented Control with tabs exists
    expect(find.text('All Buyers'), findsOneWidget);

    // Tap on "All Buyers" tab
    await tester.tap(find.text('All Buyers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify "All Buyers" view is active and renders search bar for buyers
    expect(find.text('Search buyer or category…'), findsOneWidget);
  });
}
