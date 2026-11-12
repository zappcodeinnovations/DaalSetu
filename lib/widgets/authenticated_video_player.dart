import 'package:daalsetu/widgets/media_url.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class AuthenticatedVideoPlayer extends StatefulWidget {
  const AuthenticatedVideoPlayer({
    super.key,
    required this.url,
    this.enableFullscreen = true,
  }) : _fullscreen = false,
       _sharedController = null;

  const AuthenticatedVideoPlayer._fullscreen({
    required this.url,
    required VideoPlayerController controller,
  }) : enableFullscreen = false,
       _fullscreen = true,
       _sharedController = controller;

  final String url;
  final bool enableFullscreen;
  final bool _fullscreen;
  final VideoPlayerController? _sharedController;

  @override
  State<AuthenticatedVideoPlayer> createState() =>
      _AuthenticatedVideoPlayerState();
}

class _AuthenticatedVideoPlayerState extends State<AuthenticatedVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _wasPlaying = false;
  BoxFit _fit = BoxFit.contain;
  double _zoom = 1;

  @override
  void initState() {
    super.initState();
    final shared = widget._sharedController;
    if (shared != null) {
      _controller = shared;
      _wasPlaying = shared.value.isPlaying;
      shared.addListener(_handlePlaybackChange);
    } else {
      _initialize();
    }
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
      });
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

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (!mounted || controller == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: ThemeData.dark(useMaterial3: true),
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
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
          ClipRect(
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('video-playback-surface'),
              onTap: _togglePlayback,
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
          ),
          if (!widget._fullscreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFFFB300),
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
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
    if (widget._fullscreen) {
      return Column(
        children: [
          Expanded(child: player),
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFFFFB300),
              bufferedColor: Colors.white54,
              backgroundColor: Colors.white24,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          _buildSizeControls(),
        ],
      );
    }
    return AspectRatio(aspectRatio: 16 / 9, child: player);
  }

  Widget _buildSizeControls() {
    final label = switch (_fit) {
      BoxFit.cover => 'Fill',
      BoxFit.fill => 'Stretch',
      _ => 'Fit',
    };
    return Material(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: _wasPlaying ? 'Pause' : 'Play',
              onPressed: _togglePlayback,
              icon: Icon(_wasPlaying ? Icons.pause : Icons.play_arrow),
            ),
            Expanded(
              child: PopupMenuButton<BoxFit>(
                key: const Key('video-size-mode'),
                tooltip: 'Video size mode',
                initialValue: _fit,
                onSelected: (fit) => setState(() {
                  _fit = fit;
                  _zoom = 1;
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.aspect_ratio, size: 20),
                      const SizedBox(width: 6),
                      Flexible(child: Text(label)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('video-zoom-out'),
              tooltip: 'Zoom out',
              onPressed: _zoom <= 0.5
                  ? null
                  : () => setState(() => _zoom -= 0.25),
              icon: const Icon(Icons.remove),
            ),
            TextButton(
              key: const Key('video-zoom-reset'),
              onPressed: () => setState(() => _zoom = 1),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text('${(_zoom * 100).round()}%'),
            ),
            IconButton(
              key: const Key('video-zoom-in'),
              tooltip: 'Zoom in',
              onPressed: _zoom >= 3
                  ? null
                  : () => setState(() => _zoom += 0.25),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handlePlaybackChange);
    if (widget._sharedController == null) _controller?.dispose();
    super.dispose();
  }
}
