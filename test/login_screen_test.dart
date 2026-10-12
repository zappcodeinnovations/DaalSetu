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
    final imageFinder = find.byType(Image);
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
}
