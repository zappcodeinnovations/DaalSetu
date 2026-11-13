import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// MoM 6: offer videos sit in the top media bar and open when tapped.
void main() {
  testWidgets('a video slide shows play + title and opens on tap', (tester) async {
    var opened = 0;
    final video = ProductVideo.fromJson({'id': 3, 'title': 'Loading yard', 'video': '/media/offer.mp4'});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: OfferVideoSlide(video: video, onTap: () => opened++),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('Loading yard'), findsOneWidget);
    expect(find.text('Tap to play'), findsOneWidget);
    await tester.tap(find.byType(OfferVideoSlide));
    expect(opened, 1);
  });
}
