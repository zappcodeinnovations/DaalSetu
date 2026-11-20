import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The app's builder (lib/app.dart) wraps every route in SafeArea(top: false, ...): with a 48 px system navigation
// bar the last item of a list that has its own explicit padding must still end above it.
void main() {
  testWidgets('the last list item stays above the system navigation bar and the floating bar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 800), padding: EdgeInsets.only(top: 24, bottom: 48)),
        child: MaterialApp(
          builder: (context, child) => SafeArea(top: false, left: false, right: false, child: child!),
          home: Scaffold(
            extendBody: false,
            bottomNavigationBar: const SizedBox(key: Key('bar'), height: 88),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [for (var i = 0; i < 30; i++) SizedBox(key: Key('item$i'), height: 60, child: Text('row $i'))],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final lastBottom = tester.getBottomLeft(find.byKey(const Key('item29'))).dy;
    final barTop = tester.getTopLeft(find.byKey(const Key('bar'))).dy;
    expect(lastBottom, lessThanOrEqualTo(barTop));
    // The bar itself is above the system navigation bar (800 - 48).
    expect(tester.getBottomLeft(find.byKey(const Key('bar'))).dy, lessThanOrEqualTo(752));
  });
}
