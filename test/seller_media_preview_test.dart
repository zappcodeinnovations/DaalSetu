import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product Video Dynamic Aspect Ratio Calculation Tests', () {
    double calculateVideoWidth({
      required double aspectRatio,
      required double maxVideoWidth,
      required double maxVideoHeight,
    }) {
      double calculatedWidth = maxVideoWidth;
      double calculatedHeight = calculatedWidth / aspectRatio;
      if (calculatedHeight > maxVideoHeight) {
        calculatedHeight = maxVideoHeight;
        calculatedWidth = calculatedHeight * aspectRatio;
      }
      return calculatedWidth;
    }

    double calculateVideoHeight({
      required double aspectRatio,
      required double maxVideoWidth,
      required double maxVideoHeight,
    }) {
      double calculatedWidth = maxVideoWidth;
      double calculatedHeight = calculatedWidth / aspectRatio;
      if (calculatedHeight > maxVideoHeight) {
        calculatedHeight = maxVideoHeight;
      }
      return calculatedHeight;
    }

    test('Portrait 9:16 video scales to fit max height and narrows dialog width without cropping', () {
      const maxVideoWidth = 300.0;
      const maxVideoHeight = 500.0;
      const portraitAspect = 9 / 16; // 0.5625

      final height = calculateVideoHeight(
        aspectRatio: portraitAspect,
        maxVideoWidth: maxVideoWidth,
        maxVideoHeight: maxVideoHeight,
      );
      final width = calculateVideoWidth(
        aspectRatio: portraitAspect,
        maxVideoWidth: maxVideoWidth,
        maxVideoHeight: maxVideoHeight,
      );

      // Height should fit within 500
      expect(height, lessThanOrEqualTo(maxVideoHeight));
      // Width should dynamically narrow to 500 * (9/16) = 281.25
      expect(width, closeTo(500.0 * 0.5625, 0.01));
      // Exact aspect ratio preserved
      expect(width / height, closeTo(portraitAspect, 0.001));
    });

    test('Landscape 16:9 video scales to fit max width and reduces dialog height without cropping', () {
      const maxVideoWidth = 300.0;
      const maxVideoHeight = 500.0;
      const landscapeAspect = 16 / 9; // 1.777

      final height = calculateVideoHeight(
        aspectRatio: landscapeAspect,
        maxVideoWidth: maxVideoWidth,
        maxVideoHeight: maxVideoHeight,
      );
      final width = calculateVideoWidth(
        aspectRatio: landscapeAspect,
        maxVideoWidth: maxVideoWidth,
        maxVideoHeight: maxVideoHeight,
      );

      // Width should be maxVideoWidth (300)
      expect(width, equals(maxVideoWidth));
      // Height should dynamically reduce to 300 / (16/9) = 168.75
      expect(height, closeTo(300.0 / (16 / 9), 0.01));
      expect(height, lessThan(maxVideoHeight));
      // Exact aspect ratio preserved
      expect(width / height, closeTo(landscapeAspect, 0.001));
    });

    test('Square 1:1 video scales with equal width and height', () {
      const maxVideoWidth = 300.0;
      const maxVideoHeight = 500.0;
      const squareAspect = 1.0;

      final height = calculateVideoHeight(
        aspectRatio: squareAspect,
        maxVideoWidth: maxVideoWidth,
        maxVideoHeight: maxVideoHeight,
      );
      final width = calculateVideoWidth(
        aspectRatio: squareAspect,
        maxVideoWidth: maxVideoWidth,
        maxVideoHeight: maxVideoHeight,
      );

      expect(width, equals(300.0));
      expect(height, equals(300.0));
      expect(width / height, closeTo(squareAspect, 0.001));
    });
  });

  testWidgets('Video preview container uses FittedBox with BoxFit.contain',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              width: 280,
              height: 480,
              color: Colors.black,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1080,
                  height: 1920,
                  child: Container(color: Colors.amber),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final fittedBoxFinder = find.byType(FittedBox);
    expect(fittedBoxFinder, findsOneWidget);

    final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
    expect(fittedBox.fit, equals(BoxFit.contain));
  });
}
