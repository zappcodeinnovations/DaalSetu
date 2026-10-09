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
      final controller = VideoPlayerController.networkUrl(
        resolveMediaUri(widget.url),
        httpHeaders: token == null || token.isEmpty
            ? const {}
            : {'Authorization': 'Bearer $token'},
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
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
    return Column(
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
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
