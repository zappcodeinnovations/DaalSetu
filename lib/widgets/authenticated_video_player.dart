import 'package:daalsetu/widgets/media_url.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Offer video player.
///
/// Inline it shows tap-to-play, a seek bar, the time, a mute button and a full-screen button.
/// With [fullControls] (or in the full-screen page) it also has play / pause, 10 s skip,
/// volume, playback speed, fit / fill / stretch, zoom and rotate. A portrait (mobile) video opens
/// upright, a landscape video opens rotated; the rotate button switches between the two.
/// Two-finger pinch zoom works everywhere.
class AuthenticatedVideoPlayer extends StatefulWidget {
  const AuthenticatedVideoPlayer({
    super.key,
    required this.url,
    this.enableFullscreen = true,
    this.fullControls = false,
  }) : _fullscreen = false,
       _sharedController = null;

  const AuthenticatedVideoPlayer._fullscreen({
    required this.url,
    required VideoPlayerController controller,
  }) : enableFullscreen = false,
       fullControls = true,
       _fullscreen = true,
       _sharedController = controller;

  final String url;
  final bool enableFullscreen;

  /// Show every control under the video (use on a page of its own, e.g. product details).
  final bool fullControls;
  final bool _fullscreen;
  final VideoPlayerController? _sharedController;

  @override
  State<AuthenticatedVideoPlayer> createState() =>
      _AuthenticatedVideoPlayerState();
}

String _clock(Duration value) {
  final total = value.inSeconds < 0 ? 0 : value.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

class _AuthenticatedVideoPlayerState extends State<AuthenticatedVideoPlayer> {
  static const _accent = Color(0xFFFFB300);
  static const _speeds = <double>[0.5, 1.0, 1.5, 2.0];

  VideoPlayerController? _controller;
  Object? _error;
  bool _wasPlaying = false;
  BoxFit _fit = BoxFit.contain;
  double _zoom = 1;
  double _volume = 1;
  bool _muted = false;
  double _speed = 1;
  bool _landscape = false;
  bool _orientationTouched = false;

  bool get _full => widget.fullControls || widget._fullscreen;

  /// Two-finger (pinch) zoom, like the offer images. Panning is only enabled
  /// once zoomed in, so a one-finger drag still scrolls the page.
  final TransformationController _pinch = TransformationController();
  bool _pinched = false;

  void _handlePinchChange() {
    final pinched = _pinch.value.getMaxScaleOnAxis() > 1.01;
    if (pinched != _pinched && mounted) setState(() => _pinched = pinched);
  }

  void _resetPinch() => _pinch.value = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _pinch.addListener(_handlePinchChange);
    final shared = widget._sharedController;
    if (shared != null) {
      _controller = shared;
      _wasPlaying = shared.value.isPlaying;
      _volume = shared.value.volume;
      _muted = shared.value.volume == 0;
      shared.addListener(_handlePlaybackChange);
      _useVideoOrientation(shared);
    } else {
      _initialize();
    }
  }

  /// A mobile (portrait) video stays upright, a landscape one is turned sideways.
  void _useVideoOrientation(VideoPlayerController controller) {
    if (!_full) return;
    final size = controller.value.size;
    _landscape = size.width > size.height;
    _applyOrientation();
  }

  Future<void> _applyOrientation() async {
    if (!_full) return;
    _orientationTouched = true;
    await SystemChrome.setPreferredOrientations(
      _landscape
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [DeviceOrientation.portraitUp],
    );
    await SystemChrome.setEnabledSystemUIMode(
      _landscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _toggleRotate() {
    setState(() => _landscape = !_landscape);
    _applyOrientation();
  }

  Future<void> _initialize() async {
    final previous = _controller;
    _controller = null;
    _error = null;
    if (previous != null) {
      previous.removeListener(_handlePlaybackChange);
      await previous.dispose();
    }
    try {
      final token = await AppPreferences.getAccessToken();
      final hasToken = token != null && token.isNotEmpty;
      final uri = resolveMediaUri(widget.url);
      final controller = VideoPlayerController.networkUrl(
        // Native players can drop custom headers (redirects, iOS AVPlayer), so the
        // preview endpoint also accepts the token as ?token=.
        hasToken
            ? uri.replace(
                queryParameters: {...uri.queryParameters, 'token': token},
              )
            : uri,
        httpHeaders: hasToken ? {'Authorization': 'Bearer $token'} : const {},
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(_handlePlaybackChange);
      setState(() {
        _controller = controller;
        _wasPlaying = controller.value.isPlaying;
        _volume = controller.value.volume;
        _muted = false;
        _speed = 1;
      });
      _useVideoOrientation(controller);
    } catch (error) {
      debugPrint('🎬 Media video failed: ${widget.url} ($error)');
      if (mounted) setState(() => _error = error);
    }
  }

  void _handlePlaybackChange() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      setState(() => _wasPlaying = isPlaying);
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _skip(int seconds) async {
    final controller = _controller;
    if (controller == null) return;
    final duration = controller.value.duration;
    var target = controller.value.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    await controller.seekTo(target);
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    final mute = !_muted;
    await controller.setVolume(mute ? 0 : (_volume <= 0 ? 1 : _volume));
    if (!mute && _volume <= 0) _volume = 1;
    if (mounted) setState(() => _muted = mute);
  }

  Future<void> _setVolume(double value) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setVolume(value);
    if (mounted) {
      setState(() {
        _volume = value;
        _muted = value <= 0;
      });
    }
  }

  Future<void> _setSpeed(double speed) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setPlaybackSpeed(speed);
    if (mounted) setState(() => _speed = speed);
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (!mounted || controller == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: ThemeData.dark(useMaterial3: true),
          child: OrientationBuilder(
            builder: (context, orientation) => Scaffold(
              backgroundColor: Colors.black,
              // Sideways the video needs the whole height, so the header is hidden.
              appBar: orientation == Orientation.landscape
                  ? null
                  : AppBar(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      iconTheme: const IconThemeData(color: Colors.white),
                      titleTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      systemOverlayStyle: SystemUiOverlayStyle.light,
                      title: const Text('Offer Video'),
                    ),
              body: SafeArea(
                top: false,
                child: AuthenticatedVideoPlayer._fullscreen(
                  url: widget.url,
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white70,
                  size: 34,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Video could not be loaded',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _initialize,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final player = ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tap = play / pause; two fingers = zoom (the tap and the pinch share
          // one gesture arena, so neither blocks the other).
          GestureDetector(
            key: const Key('video-playback-surface'),
            behavior: HitTestBehavior.opaque,
            onTap: _togglePlayback,
            onDoubleTap: _resetPinch,
            child: InteractiveViewer(
              key: const Key('video-pinch-zoom'),
              transformationController: _pinch,
              minScale: 1,
              maxScale: 5,
              panEnabled: _pinched,
              child: ClipRect(
                key: const Key('video-viewport'),
                child: Transform.scale(
                  scale: _zoom,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: _fit,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _wasPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black54,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
          if (!_full) _buildInlineBar(controller),
          if (widget.enableFullscreen)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                key: const Key('video-fullscreen-button'),
                tooltip: 'Open full screen',
                onPressed: _openFullscreen,
                icon: const Icon(Icons.fullscreen_rounded),
              ),
            ),
        ],
      ),
    );
    if (_full) {
      return Column(
        children: [
          Expanded(child: player),
          _buildFullControls(controller),
        ],
      );
    }
    return AspectRatio(aspectRatio: 16 / 9, child: player);
  }

  static const _progressColors = VideoProgressColors(
    playedColor: _accent,
    bufferedColor: Colors.white54,
    backgroundColor: Colors.white24,
  );

  /// Inline: seek bar with the time and a mute button over the bottom of the video.
  Widget _buildInlineBar(VideoPlayerController controller) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black54],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 2),
              child: Row(
                children: [
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controller,
                    builder: (_, value, __) => Text(
                      '${_clock(value.position)} / ${_clock(value.duration)}',
                      key: const Key('video-time'),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('video-mute-button'),
                    tooltip: _muted ? 'Unmute' : 'Mute',
                    visualDensity: VisualDensity.compact,
                    onPressed: _toggleMute,
                    icon: Icon(
                      _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: _progressColors,
              padding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tight(Widget button) => SizedBox(width: 40, height: 40, child: button);

  /// Full controls under the video: seek bar with time, then play / skip / volume / speed,
  /// then size, zoom and rotate.
  Widget _buildFullControls(VideoPlayerController controller) {
    final fitLabel = switch (_fit) {
      BoxFit.cover => 'Fill',
      BoxFit.fill => 'Stretch',
      _ => 'Fit',
    };
    // Always light-on-black, whatever theme the page around the video uses.
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Material(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (_, value, __) => Row(
                children: [
                  Text(
                    _clock(value.position),
                    key: const Key('video-time'),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: _progressColors,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                  Text(
                    _clock(value.duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _tight(
                  IconButton(
                    key: const Key('video-play-button'),
                    padding: EdgeInsets.zero,
                    tooltip: _wasPlaying ? 'Pause' : 'Play',
                    onPressed: _togglePlayback,
                    icon: Icon(_wasPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                ),
                _tight(
                  IconButton(
                    key: const Key('video-skip-back'),
                    padding: EdgeInsets.zero,
                    tooltip: 'Back 10 seconds',
                    onPressed: () => _skip(-10),
                    icon: const Icon(Icons.replay_10_rounded),
                  ),
                ),
                _tight(
                  IconButton(
                    key: const Key('video-skip-forward'),
                    padding: EdgeInsets.zero,
                    tooltip: 'Forward 10 seconds',
                    onPressed: () => _skip(10),
                    icon: const Icon(Icons.forward_10_rounded),
                  ),
                ),
                _tight(
                  IconButton(
                    key: const Key('video-mute-button'),
                    padding: EdgeInsets.zero,
                    tooltip: _muted ? 'Unmute' : 'Mute',
                    onPressed: _toggleMute,
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      activeTrackColor: _accent,
                      thumbColor: _accent,
                      inactiveTrackColor: Colors.white24,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      key: const Key('video-volume'),
                      value: _muted ? 0 : _volume,
                      onChanged: _setVolume,
                    ),
                  ),
                ),
                PopupMenuButton<double>(
                  key: const Key('video-speed-menu'),
                  tooltip: 'Playback speed',
                  initialValue: _speed,
                  onSelected: _setSpeed,
                  itemBuilder: (_) => [
                    for (final speed in _speeds)
                      PopupMenuItem(value: speed, child: Text('${speed}x')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      '${_speed}x',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: PopupMenuButton<BoxFit>(
                    key: const Key('video-size-mode'),
                    tooltip: 'Video size mode',
                    initialValue: _fit,
                    onSelected: (fit) => setState(() {
                      _fit = fit;
                      _zoom = 1;
                      _resetPinch();
                    }),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: BoxFit.contain, child: Text('Fit')),
                      PopupMenuItem(
                        value: BoxFit.cover,
                        child: Text('Fill (crop)'),
                      ),
                      PopupMenuItem(value: BoxFit.fill, child: Text('Stretch')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.aspect_ratio, size: 20),
                          const SizedBox(width: 6),
                          Flexible(child: Text(fitLabel)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                _tight(
                  IconButton(
                    key: const Key('video-zoom-out'),
                    padding: EdgeInsets.zero,
                    tooltip: 'Zoom out',
                    onPressed: _zoom <= 0.5
                        ? null
                        : () => setState(() => _zoom -= 0.25),
                    icon: const Icon(Icons.remove),
                  ),
                ),
                TextButton(
                  key: const Key('video-zoom-reset'),
                  onPressed: () => setState(() {
                    _zoom = 1;
                    _resetPinch();
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(52, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('${(_zoom * 100).round()}%'),
                ),
                _tight(
                  IconButton(
                    key: const Key('video-zoom-in'),
                    padding: EdgeInsets.zero,
                    tooltip: 'Zoom in',
                    onPressed: _zoom >= 3
                        ? null
                        : () => setState(() => _zoom += 0.25),
                    icon: const Icon(Icons.add),
                  ),
                ),
                _tight(
                  IconButton(
                    key: const Key('video-rotate-button'),
                    padding: EdgeInsets.zero,
                    tooltip: _landscape ? 'Rotate to portrait' : 'Rotate to landscape',
                    onPressed: _toggleRotate,
                    icon: Icon(
                      _landscape
                          ? Icons.stay_current_portrait_rounded
                          : Icons.stay_current_landscape_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _pinch.removeListener(_handlePinchChange);
    _pinch.dispose();
    _controller?.removeListener(_handlePlaybackChange);
    if (widget._sharedController == null) _controller?.dispose();
    if (_orientationTouched) {
      // Give the phone its normal rotation back when the video page closes.
      SystemChrome.setPreferredOrientations(const []);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }
}
