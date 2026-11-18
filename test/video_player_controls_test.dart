import 'package:daalsetu/widgets/authenticated_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _Platform extends VideoPlayerPlatform {
  Size videoSize = const Size(1080, 1920);
  double volume = 1;
  double speed = 1;
  Duration position = const Duration(seconds: 30);

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(minutes: 2),
      size: videoSize,
    ),
  );
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async => this.volume = volume;
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async => this.speed = speed;
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration position) async => this.position = position;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(color: Colors.amber);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Platform platform;
  late VideoPlayerPlatform original;
  final orientationCalls = <List<dynamic>>[];

  setUp(() {
    original = VideoPlayerPlatform.instance;
    platform = _Platform();
    VideoPlayerPlatform.instance = platform;
    FlutterSecureStorage.setMockInitialValues({});
    orientationCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientationCalls.add(List<dynamic>.from(call.arguments as List));
        }
        return null;
      },
    );
  });
  tearDown(() {
    VideoPlayerPlatform.instance = original;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpPlayer(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: AuthenticatedVideoPlayer(
            url: 'https://example.com/offer.mp4',
            enableFullscreen: false,
            fullControls: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> closePlayer(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('the video page has the full set of controls and keeps pinch zoom', (tester) async {
    await pumpPlayer(tester);
    for (final key in const [
      'video-play-button',
      'video-skip-back',
      'video-skip-forward',
      'video-mute-button',
      'video-volume',
      'video-speed-menu',
      'video-size-mode',
      'video-zoom-out',
      'video-zoom-in',
      'video-rotate-button',
      'video-pinch-zoom',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(tester.takeException(), isNull);
    await closePlayer(tester);
  });

  testWidgets('mute, skip and speed reach the player', (tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.byKey(const Key('video-mute-button')));
    await tester.pumpAndSettle();
    expect(platform.volume, 0);
    await tester.tap(find.byKey(const Key('video-mute-button')));
    await tester.pumpAndSettle();
    expect(platform.volume, 1);

    // The video starts at 00:00: +10 s, +10 s, then -10 s, and it never goes below zero.
    await tester.tap(find.byKey(const Key('video-skip-forward')));
    await tester.pumpAndSettle();
    expect(platform.position, const Duration(seconds: 10));
    await tester.tap(find.byKey(const Key('video-skip-forward')));
    await tester.pumpAndSettle();
    expect(platform.position, const Duration(seconds: 20));
    await tester.tap(find.byKey(const Key('video-skip-back')));
    await tester.pumpAndSettle();
    expect(platform.position, const Duration(seconds: 10));
    await tester.tap(find.byKey(const Key('video-skip-back')));
    await tester.tap(find.byKey(const Key('video-skip-back')));
    await tester.pumpAndSettle();
    expect(platform.position, Duration.zero);

    // The player applies the speed when it plays, so start playback first.
    await tester.tap(find.byKey(const Key('video-play-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('video-speed-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5x').last);
    await tester.pumpAndSettle();
    expect(platform.speed, 1.5);
    expect(find.text('1.5x'), findsOneWidget);
    await closePlayer(tester);
  });

  testWidgets('a mobile (portrait) video opens upright and rotate switches to landscape and back', (tester) async {
    await pumpPlayer(tester);
    expect(orientationCalls.last, ['DeviceOrientation.portraitUp']);

    await tester.tap(find.byKey(const Key('video-rotate-button')));
    await tester.pumpAndSettle();
    expect(orientationCalls.last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);

    await tester.tap(find.byKey(const Key('video-rotate-button')));
    await tester.pumpAndSettle();
    expect(orientationCalls.last, ['DeviceOrientation.portraitUp']);

    // Leaving the page gives the phone its normal rotation back.
    await closePlayer(tester);
    expect(orientationCalls.last, isEmpty);
  });

  testWidgets('a landscape video opens rotated sideways', (tester) async {
    platform.videoSize = const Size(1920, 1080);
    await pumpPlayer(tester);
    expect(orientationCalls.last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
    await closePlayer(tester);
  });

  testWidgets('the inline player shows the time and a mute button', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AuthenticatedVideoPlayer(url: 'https://example.com/offer.mp4')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('video-time')), findsOneWidget);
    expect(find.text('00:00 / 02:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('video-mute-button')));
    await tester.pumpAndSettle();
    expect(platform.volume, 0);
    // The phone stays in its normal rotation while the video is only inline.
    expect(orientationCalls, isEmpty);
    await closePlayer(tester);
  });
}
