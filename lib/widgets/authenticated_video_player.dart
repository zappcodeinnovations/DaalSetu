import 'package:daalsetu/widgets/media_url.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AuthenticatedVideoPlayer extends StatefulWidget {
  const AuthenticatedVideoPlayer({super.key, required this.url});
  final String url;

  @override
  State<AuthenticatedVideoPlayer> createState() =>
      _AuthenticatedVideoPlayerState();
}

class _AuthenticatedVideoPlayerState extends State<AuthenticatedVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final token = await AppPreferences.getAccessToken();
      final hasToken = token != null && token.isNotEmpty;
      final uri = resolveMediaUri(widget.url);
      final controller = VideoPlayerController.networkUrl(
        // Native players can drop custom headers (redirects, iOS AVPlayer), so the
        // preview endpoint also accepts the token as ?token=.
        hasToken ? uri.replace(queryParameters: {...uri.queryParameters, 'token': token}) : uri,
        httpHeaders: hasToken ? {'Authorization': 'Bearer $token'} : const {},
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      debugPrint('🎬 Media video failed: ${widget.url} ($error)');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: Text('Video could not be loaded')),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final videoSize = controller.value.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: videoSize.width > 0 ? videoSize.width : 16,
              height: videoSize.height > 0 ? videoSize.height : 9,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        IconButton.filled(
          tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
          onPressed: () {
            setState(() {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            });
          },
          icon: Icon(
            controller.value.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
