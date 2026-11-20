import 'package:daalsetu/widgets/dispatch_bills_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  Future<void> open(WidgetTester tester, Future<List<String>> Function() picker, void Function(List<String>?) done) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => done(await askDispatchBills(picker: picker)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('choosing a file does not dispatch: it is listed and needs Confirm Dispatch', (tester) async {
    List<String>? result = const ['not-answered'];
    await open(tester, () async => ['/storage/bill_1.pdf'], (value) => result = value);

    await tester.tap(find.text('Choose Files'));
    await tester.pumpAndSettle();

    expect(result, ['not-answered']); // nothing was dispatched by the pick
    expect(find.text('bill_1.pdf'), findsOneWidget);
    expect(find.text('Confirm Dispatch (1 file)'), findsOneWidget);
    expect(find.text('Dispatch without bill'), findsNothing);

    await tester.tap(find.text('Confirm Dispatch (1 file)'));
    await tester.pumpAndSettle();
    expect(result, ['/storage/bill_1.pdf']);
  });

  testWidgets('a picked file can be removed again, and the buttons share one width', (tester) async {
    List<String>? result = const ['not-answered'];
    await open(tester, () async => ['/a/one.png'], (value) => result = value);

    final choose = tester.getSize(find.widgetWithText(OutlinedButton, 'Choose Files'));
    final skip = tester.getSize(find.widgetWithText(OutlinedButton, 'Dispatch without bill'));
    final cancel = tester.getSize(find.widgetWithText(OutlinedButton, 'Cancel'));
    expect(skip.width, choose.width);
    expect(cancel.width, choose.width);

    await tester.tap(find.text('Choose Files'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Dispatch without bill'), findsOneWidget);

    await tester.tap(find.text('Dispatch without bill'));
    await tester.pumpAndSettle();
    expect(result, isEmpty);
  });

  testWidgets('Cancel returns null', (tester) async {
    List<String>? result = const ['not-answered'];
    await open(tester, () async => [], (value) => result = value);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
