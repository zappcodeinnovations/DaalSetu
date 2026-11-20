import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/keyboard_dismiss_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required bool bar, Widget? home}) => MaterialApp(
      navigatorObservers: [KeyboardRouteObserver()],
      builder: (context, child) => KeyboardDismissLayer(showAccessoryBar: bar, child: child!),
      home: home ??
          Scaffold(
            body: Column(children: [
              const TextField(key: Key('a'), keyboardType: TextInputType.number),
              const TextField(key: Key('b')),
              const SizedBox(height: 300, child: Center(child: Text('empty area'))),
            ]),
          ),
    );

bool _focused(WidgetTester t, String key) =>
    t.widget<EditableText>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText))).focusNode.hasFocus;

void main() {
  placeBidStyleDialogTest();
  testWidgets('a tap outside a field closes the keyboard (focus), a tap in a field keeps it', (tester) async {
    await tester.pumpWidget(_app(bar: false));
    await tester.tap(find.byKey(const Key('a')));
    await tester.pump();
    expect(_focused(tester, 'a'), isTrue);
    await tester.tap(find.text('empty area'));
    await tester.pump();
    expect(_focused(tester, 'a'), isFalse);
  });

  testWidgets('the iPhone bar has Previous / Next / Done and they work', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(bar: true));
    await tester.tap(find.byKey(const Key('a')));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keyboard-next')));
    await tester.pump();
    expect(_focused(tester, 'b'), isTrue);
    await tester.tap(find.byKey(const Key('keyboard-previous')));
    await tester.pump();
    expect(_focused(tester, 'a'), isTrue);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(_focused(tester, 'a'), isFalse);
  });

  testWidgets('no bar on Android (bar: false) even with the keyboard open', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(bar: false));
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('a pushed screen whose header has no back arrow of its own gets one; a root screen does not', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: const HeroHeader(title: 'Root'),
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => Scaffold(appBar: const HeroHeader(title: 'Detail'))),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    expect(find.byTooltip('Back'), findsNothing);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
  });
}

void placeBidStyleDialogTest() {
  testWidgets('a dialog (Place Bid style): tapping its empty area closes the keyboard and keeps the dialog open', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => KeyboardDismissLayer(showAccessoryBar: false, child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Place Bid'),
                content: SizedBox(
                  width: 300,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(key: Key('price')),
                    SizedBox(height: 120, child: Center(child: Text('blank area in dialog'))),
                  ]),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('price')));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    await tester.tap(find.text('blank area in dialog'));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isFalse);
    expect(find.text('Place Bid'), findsOneWidget); // still open
  });
}
