import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _video = ProductVideo(id: 1, title: 'Product video', videoUrl: '/media/v.mp4', downloadUrl: '', isPrimary: true);

Widget _slide({String? poster}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 320, height: 200, child: OfferVideoSlide(video: _video, onTap: () {}, posterUrl: poster)),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('with an offer photo the video poster is that photo (no black box)', (tester) async {
    await tester.pumpWidget(_slide(poster: '/media/p.jpg'));
    await tester.pump();
    expect(find.byKey(const Key('offer-video-poster-photo')), findsOneWidget);
  });

  testWidgets('without a photo or a readable frame the poster is the branded gradient, not black', (tester) async {
    await tester.pumpWidget(_slide());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('offer-video-poster-gradient')), findsOneWidget);
  });
}
