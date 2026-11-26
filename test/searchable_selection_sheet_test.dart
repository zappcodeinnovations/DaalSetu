import 'package:daalsetu/widgets/searchable_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the State / City picker opens without the keyboard and keeps its size when it opens', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(children: [
            const TextField(key: Key('address')),
            TextButton(
              onPressed: () => showSearchableSelectionSheet<String>(
                context: context,
                title: 'Select State',
                options: const ['Maharashtra', 'Gujarat', 'Goa'],
                labelBuilder: (v) => v,
              ),
              child: const Text('open'),
            ),
          ]),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('address')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // The address keyboard was closed and the search box did not open a new one.
    expect(tester.testTextInput.isVisible, isFalse);
    final before = tester.getRect(find.text('Select State'));

    // A keyboard appearing (the user taps Search) does not move the sheet.
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Select State')), before);
    expect(find.text('Goa'), findsOneWidget);
  });
}
