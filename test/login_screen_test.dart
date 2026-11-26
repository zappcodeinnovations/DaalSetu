import 'package:daalsetu/modules/Auth/login/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginScreen displays full DaalSetu logo unclipped with BoxFit.contain and padding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify logo image
    final imageFinder = find.byWidgetPredicate(
      (w) => w is Image && (w.image is AssetImage) && (w.image as AssetImage).assetName == 'assets/images/app_icon.jpeg',
    );
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.fit, BoxFit.contain);
    expect((imageWidget.image as AssetImage).assetName,
        'assets/images/app_icon.jpeg');

    // Verify padding wraps the image inside ClipOval
    final paddingFinder = find.ancestor(
      of: imageFinder,
      matching: find.byType(Padding),
    );
    expect(paddingFinder, findsWidgets);

    final paddingWidget = tester.widget<Padding>(paddingFinder.first);
    expect(paddingWidget.padding, const EdgeInsets.all(10));
  });

  testWidgets('LoginScreen shows the tagline and Pulse Trading Platform beneath the title (no KISOR)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Smarter Trading. Stronger Connections.'), findsOneWidget);
    expect(find.text('Pulse Trading Platform'), findsOneWidget);
    expect(find.text('KISOR'), findsNothing);
    expect(find.text('Operations control centre'), findsNothing);
  });
}
