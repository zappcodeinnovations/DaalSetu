import 'package:daalsetu/widgets/media_url.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AuthenticatedVideoPlayer extends StatefulWidget {
  const AuthenticatedVideoPlayer({
    super.key,
    required this.url,
    this.enableFullscreen = true,
  });
  final String url;
  final bool enableFullscreen;

  @override
  State<AuthenticatedVideoPlayer> createState() =>
      _AuthenticatedVideoPlayerState();
}

class _AuthenticatedVideoPlayerState extends State<AuthenticatedVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _initialize();
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
    await _controller?.pause();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Offer Video'),
          ),
          body: Center(
            child: AuthenticatedVideoPlayer(
              url: widget.url,
              enableFullscreen: false,
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
    final actualAspectRatio = controller.value.aspectRatio <= 0
        ? 16 / 9
        : controller.value.aspectRatio;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: actualAspectRatio,
                child: VideoPlayer(controller),
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
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handlePlaybackChange);
    _controller?.dispose();
    super.dispose();
  }
}
