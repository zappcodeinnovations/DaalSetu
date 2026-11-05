import 'package:daalsetu/widgets/authenticated_video_player.dart';
import 'package:daalsetu/modules/seller/products/view/seller_media_gallery_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
// The player already depends on this platform interface; fake native playback.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  int created = 0;
  int disposed = 0;
  Duration position = Duration.zero;
  Size videoSize = const Size(1080, 1920);

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      ++created;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(minutes: 1),
      size: videoSize,
    ),
  );
  @override
  Future<void> dispose(int playerId) async {
    disposed++;
  }

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
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration position) async {
    this.position = position;
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.amber);
}

void main() {
  late _VideoPlatform platform;
  late VideoPlayerPlatform original;
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    original = VideoPlayerPlatform.instance;
    platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => VideoPlayerPlatform.instance = original);

  Future<void> openVideo(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Reproduce the light theme whose dark title leaked onto the black header.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(color: Color(0xFF0F172A)),
            iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          ),
        ),
        home: const Scaffold(
          body: Center(
            child: AuthenticatedVideoPlayer(
              url: 'https://example.com/offer.mp4',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('video-fullscreen-button')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'fullscreen header is white and portrait video fills available height',
    (tester) async {
      await openVideo(tester);
      final title = find.text('Offer Video');
      expect(
        DefaultTextStyle.of(tester.element(title)).style.color,
        Colors.white,
      );
      expect(
        IconTheme.of(tester.element(find.byType(BackButton))).color,
        Colors.white,
      );
      final viewport = tester.getSize(
        find.byKey(const Key('video-viewport')).last,
      );
      expect(viewport.width, 360);
      expect(viewport.height, greaterThan(600));
      expect(
        tester.getRect(find.byType(VideoPlayer).last).height,
        greaterThan(600),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('size menu and zoom controls change the rendered video', (
    tester,
  ) async {
    await openVideo(tester);
    await tester.tap(find.byKey(const Key('video-size-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill (crop)'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FittedBox>(find.byType(FittedBox).last).fit,
      BoxFit.cover,
    );
    await tester.tap(find.byKey(const Key('video-zoom-in')));
    await tester.pump();
    expect(find.text('125%'), findsOneWidget);
    final viewport = find.byKey(const Key('video-viewport')).last;
    final transform = tester.widget<Transform>(
      find.descendant(of: viewport, matching: find.byType(Transform)).first,
    );
    expect(transform.transform.storage[0], 1.25);
    await tester.tap(find.byKey(const Key('video-zoom-out')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('video-zoom-out')));
    await tester.pump();
    expect(find.text('75%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('video-zoom-reset')));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('video-size-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stretch').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FittedBox>(find.byType(FittedBox).last).fit,
      BoxFit.fill,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'fullscreen preserves playback position and controller ownership',
    (tester) async {
      await openVideo(tester);
      final controller = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer).last)
          .controller;
      await controller.seekTo(const Duration(seconds: 25));
      await controller.play();
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(platform.created, 1);
      expect(platform.disposed, 0);
      expect(controller.value.position, const Duration(seconds: 25));
      expect(controller.value.isPlaying, isTrue);
      await controller.pause();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      // Native disposal finishes asynchronously after its event stream closes.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(platform.disposed, 1);
    },
  );

  for (final size in [
    const Size(354.4, 844),
    const Size(360, 640),
    const Size(800, 360),
  ]) {
    testWidgets('product video dialog fits $size with visible controls', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const DynamicVideoPreviewDialog(
                    url: 'https://example.com/video.mp4',
                  ),
                ),
                child: const Text('Open video'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open video'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Play').hitTestable(), findsOneWidget);
      expect(find.text('Close').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DynamicVideoPreviewDialog), findsNothing);
    });
  }

  testWidgets('landscape phone keeps size controls usable without overflow', (
    tester,
  ) async {
    platform.videoSize = const Size(1920, 1080);
    await openVideo(tester);
    tester.view.physicalSize = const Size(800, 360);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('video-zoom-in')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('video-size-mode')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
