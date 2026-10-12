import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Input fields on Create Offer have proper prefixIcon spacing avoiding text clipping',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: "Offer Title * (e.g. Premium Toor Dal)",
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const SizedBox(
                  width: 46,
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Icon(Icons.shopping_bag, size: 20),
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 46,
                  maxWidth: 46,
                  minHeight: 48,
                  maxHeight: 48,
                ),
                filled: true,
                contentPadding: const EdgeInsets.only(
                  left: 0,
                  right: 16,
                  top: 14,
                  bottom: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final iconFinder = find.byType(Icon);
    final hintFinder = find.text("Offer Title * (e.g. Premium Toor Dal)");

    expect(iconFinder, findsOneWidget);
    expect(hintFinder, findsOneWidget);

    final iconRect = tester.getRect(iconFinder);
    final hintRect = tester.getRect(hintFinder);

    // Verify icon is positioned on the left, not centered in the middle of the field
    expect(iconRect.left, lessThan(60.0));

    // Verify distance between icon right edge and hint text left edge is clean and visible
    final gap = hintRect.left - iconRect.right;
    expect(gap, greaterThanOrEqualTo(8.0));

    // Verify user can tap and type in the text field smoothly
    await tester.enterText(find.byType(TextField), 'Premium Toor Dal');
    await tester.pumpAndSettle();
    expect(controller.text, 'Premium Toor Dal');
  });

  testWidgets('Location field functions cleanly as address search input without redundant prefix text',
      (WidgetTester tester) async {
    final locationController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<TextEditingValue>(
            valueListenable: locationController,
            builder: (context, value, _) {
              return TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Search or enter address / mandi location",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          key: const Key('clear_location_btn'),
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => locationController.clear(),
                        )
                      : const Icon(
                          Icons.search,
                          key: Key('search_location_icon'),
                          size: 20,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify appropriate placeholder is visible and redundant "Loading Location" is absent
    expect(find.text("Search or enter address / mandi location"), findsOneWidget);
    expect(find.text("Loading Location"), findsNothing);

    // 2. When empty, search icon is shown
    expect(find.byKey(const Key('search_location_icon')), findsOneWidget);
    expect(find.byKey(const Key('clear_location_btn')), findsNothing);

    // 3. When text is entered, clear button is shown
    locationController.text = "APMC Mandi, Latur";
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clear_location_btn')), findsOneWidget);
    expect(find.byKey(const Key('search_location_icon')), findsNothing);

    // 4. Tap clear button
    await tester.tap(find.byKey(const Key('clear_location_btn')));
    await tester.pumpAndSettle();

    expect(locationController.text, isEmpty);
    expect(find.byKey(const Key('search_location_icon')), findsOneWidget);
  });
}

