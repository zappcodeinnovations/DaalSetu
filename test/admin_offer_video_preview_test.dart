import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin offer video preview keeps playback controls visible', () {
    final detailSource = File(
      'lib/modules/admin_catalog/view/admin_record_detail_screen.dart',
    ).readAsStringSync();
    final playerSource = File(
      'lib/widgets/authenticated_video_player.dart',
    ).readAsStringSync();

    final previewStart = detailSource.indexOf('Widget _buildVideoPreview');
    final previewEnd = detailSource.indexOf(
      'Future<void> _launchUrl',
      previewStart,
    );
    final previewSource = detailSource.substring(previewStart, previewEnd);

    expect(previewSource, isNot(contains('height: 150')));
    expect(previewSource, contains('AuthenticatedVideoPlayer(url: url)'));
    expect(playerSource, contains("Key('video-playback-surface')"));
    expect(playerSource, contains("Key('video-fullscreen-button')"));
    expect(playerSource, contains('VideoProgressIndicator'));
    expect(playerSource, contains("label: const Text('Retry')"));
  });
}
