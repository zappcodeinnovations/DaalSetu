import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:daalsetu/modules/seller/products/view/seller_product_view.dart';
import 'package:daalsetu/widgets/offer_media_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(eventType: VideoEventType.initialized, duration: const Duration(minutes: 1), size: const Size(1080, 1920)),
  );
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(color: Colors.amber);
}

class _SellerController extends SellerProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

void main() {
  late VideoPlayerPlatform original;
  setUp(() {
    Get.reset();
    original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _VideoPlatform();
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() {
    VideoPlayerPlatform.instance = original;
    Get.reset();
  });

  Future<void> pumpHost(WidgetTester tester, void Function() open) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.light().copyWith(
          // The light theme's dark title used to leak onto the black header.
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(color: Color(0xFF0F172A)),
            iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          ),
        ),
        home: Scaffold(body: Center(child: ElevatedButton(onPressed: open, child: const Text('open')))),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('no media: nothing opens, so the caller can show the details page', (tester) async {
    late bool opened;
    await pumpHost(tester, () => opened = openOfferMedia(imageUrls: const [], videoUrls: const []));
    expect(opened, isFalse);
    expect(find.byType(OfferMediaSplitPage), findsNothing);
  });

  testWidgets('a video opens its own page with a readable white title and every control', (tester) async {
    await pumpHost(tester, () => openOfferMedia(imageUrls: const [], videoUrls: const ['https://x.test/v.mp4'], title: 'arhar daal'));
    await tester.pumpAndSettle();
    final title = find.text('arhar daal');
    expect(title, findsOneWidget);
    expect(DefaultTextStyle.of(tester.element(title)).style.color, Colors.white);
    expect(IconTheme.of(tester.element(find.byType(BackButton))).color, Colors.white);
    expect(find.byKey(const Key('video-rotate-button')), findsOneWidget);
    expect(find.byKey(const Key('video-pinch-zoom')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('photos only open the photo viewer with a counter', (tester) async {
    await pumpHost(tester, () => openOfferMedia(imageUrls: const ['https://x.test/1.jpg', 'https://x.test/2.jpg'], videoUrls: const [], title: 'Dal'));
    expect(find.byKey(const Key('offer-image-pages')), findsOneWidget);
    expect(find.text('Dal  1 / 2'), findsOneWidget);
    expect(find.byKey(const Key('offer-image-zoom-0')), findsOneWidget);
    await tester.drag(find.byKey(const Key('offer-image-pages')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Dal  2 / 2'), findsOneWidget);
  });

  testWidgets('photos and a video show split screen and each half opens on tap', (tester) async {
    await pumpHost(
      tester,
      () => openOfferMedia(
        imageUrls: const ['https://x.test/1.jpg'],
        videoUrls: const ['https://x.test/v.mp4'],
        title: 'urad daal',
      ),
    );
    expect(find.byType(OfferMediaSplitPage), findsOneWidget);
    final photos = tester.getRect(find.byKey(const Key('offer-media-photos')));
    final video = tester.getRect(find.byKey(const Key('offer-media-video')));
    // Upright phone: photos on top, video below, both visible at once.
    expect(photos.bottom, lessThanOrEqualTo(video.top));
    expect(photos.height, greaterThan(150));
    expect(video.height, greaterThan(150));

    await tester.tap(find.byKey(const Key('offer-media-video-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('video-play-button')), findsOneWidget);
    Get.back<void>();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('offer-media-photo-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offer-image-pages')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the My Products thumbnail opens the media, not the details page', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _SellerController();
    Get.put<SellerProductController>(controller);
    controller.products.assignAll([
      SellerProductModel.fromJson({
        'id': 7,
        'title': 'urad daal',
        'amount': '25.00',
        'amount_unit': 'qtl',
        'status': 'active',
        'is_active': true,
        'bag_count': 5,
        'packing_weight_kg': '10',
        'images': [
          {'image_url': 'https://x.test/1.jpg', 'is_primary': true},
        ],
        'product_videos': [
          {'video_url': 'https://x.test/v.mp4', 'title':'vid'},
        ],
      }),
    ]);
    controller.isLoading.value = false;
    await tester.pumpWidget(const GetMaterialApp(home: SellerProductView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('seller_product_media_7')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(OfferMediaSplitPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
